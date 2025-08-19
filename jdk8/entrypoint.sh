#!/bin/bash

# JDK 8u202 容器启动脚本 - 自动资源探测与配置
# 支持 cgroup v1/v2 资源限制探测和JVM参数优化

set -e

# 默认配置
DEFAULT_JAR_PATH="/app/app.jar"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ENTRYPOINT] $1"
}

# 探测cgroup版本和资源限制
detect_cgroup_resources() {
    local cpu_cores=0
    local memory_bytes=0
    local cgroup_version=""

    # 检测cgroup版本
    if [ -f /sys/fs/cgroup/cgroup.controllers ]; then
        cgroup_version="v2"
        log "检测到 cgroup v2"

        # cgroup v2 CPU限制探测
        if [ -f /sys/fs/cgroup/cpu.max ]; then
            local cpu_max=$(cat /sys/fs/cgroup/cpu.max 2>/dev/null || echo "max")
            if [ "$cpu_max" != "max" ] && [[ $cpu_max =~ ^[0-9]+[[:space:]]+[0-9]+$ ]]; then
                local cpu_quota=$(echo $cpu_max | awk '{print $1}')
                local cpu_period=$(echo $cpu_max | awk '{print $2}')
                if [ "$cpu_quota" -gt 0 ] && [ "$cpu_period" -gt 0 ]; then
                    cpu_cores=$(echo "scale=0; ($cpu_quota + $cpu_period - 1) / $cpu_period" | bc)
                    log "探测到 cgroup v2 CPU 限制: ${cpu_cores} 核 (quota=${cpu_quota}, period=${cpu_period})"
                fi
            fi
        fi

        # cgroup v2 内存限制探测
        if [ -f /sys/fs/cgroup/memory.max ]; then
            local mem_max=$(cat /sys/fs/cgroup/memory.max 2>/dev/null || echo "max")
            if [ "$mem_max" != "max" ] && [[ $mem_max =~ ^[0-9]+$ ]] && [ "$mem_max" -gt 0 ]; then
                memory_bytes=$mem_max
                log "探测到 cgroup v2 内存限制: $((memory_bytes / 1024 / 1024)) MB"
            fi
        fi

    elif [ -d /sys/fs/cgroup/cpu ] || [ -d /sys/fs/cgroup/memory ]; then
        cgroup_version="v1"
        log "检测到 cgroup v1"

        # cgroup v1 CPU限制探测
        local cpu_quota_file="/sys/fs/cgroup/cpu/cpu.cfs_quota_us"
        local cpu_period_file="/sys/fs/cgroup/cpu/cpu.cfs_period_us"

        if [ -f "$cpu_quota_file" ] && [ -f "$cpu_period_file" ]; then
            local cpu_quota=$(cat $cpu_quota_file 2>/dev/null || echo "-1")
            local cpu_period=$(cat $cpu_period_file 2>/dev/null || echo "100000")
            if [ "$cpu_quota" -gt 0 ] && [ "$cpu_period" -gt 0 ]; then
                cpu_cores=$(echo "scale=0; ($cpu_quota + $cpu_period - 1) / $cpu_period" | bc)
                log "探测到 cgroup v1 CPU 限制: ${cpu_cores} 核 (quota=${cpu_quota}, period=${cpu_period})"
            fi
        fi

        # cgroup v1 内存限制探测
        local mem_limit_file="/sys/fs/cgroup/memory/memory.limit_in_bytes"
        if [ -f "$mem_limit_file" ]; then
            local mem_limit=$(cat $mem_limit_file 2>/dev/null || echo "0")
            # 检查是否为实际限制（不是默认的巨大数值）
            if [ "$mem_limit" -gt 0 ] && [ "$mem_limit" -lt 9223372036854775807 ]; then
                memory_bytes=$mem_limit
                log "探测到 cgroup v1 内存限制: $((memory_bytes / 1024 / 1024)) MB"
            fi
        fi
    else
        log "未检测到 cgroup，将不自动配置资源参数"
    fi

    # 导出探测结果
    export DETECTED_CPU_CORES=$cpu_cores
    export DETECTED_MEMORY_BYTES=$memory_bytes
    export DETECTED_MEMORY_MB=$((memory_bytes / 1024 / 1024))
}

# 生成JVM参数（仅在探测到资源限制时）
generate_jvm_args() {
    AUTO_JVM_ARGS=""

    # 只有在探测到资源限制时才自动配置参数
    if [ "$DETECTED_MEMORY_BYTES" -gt 0 ]; then
        # 内存配置：最大75%，最小25%
        local max_heap_mb=$((DETECTED_MEMORY_MB * 75 / 100))
        local min_heap_mb=$((DETECTED_MEMORY_MB * 25 / 100))

        # 基础内存参数
        JVM_MEMORY_ARGS="-Xmx${max_heap_mb}m -Xms${min_heap_mb}m"
        AUTO_JVM_ARGS="$AUTO_JVM_ARGS $JVM_MEMORY_ARGS"

        # JDK8u202 容器感知相关参数
        JVM_CONTAINER_ARGS="-XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap"
        AUTO_JVM_ARGS="$AUTO_JVM_ARGS $JVM_CONTAINER_ARGS"

        # OOM处理
        JVM_OOM_ARGS="-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/app/logs/ -XX:+ExitOnOutOfMemoryError"
        AUTO_JVM_ARGS="$AUTO_JVM_ARGS $JVM_OOM_ARGS"

        log "内存限制配置: 最大堆=${max_heap_mb}MB (75%), 最小堆=${min_heap_mb}MB (25%)"
    fi

    if [ "$DETECTED_CPU_CORES" -gt 0 ]; then
        # CPU不足1核按1核计算
        local cpu_cores=$DETECTED_CPU_CORES
        if [ "$cpu_cores" -lt 1 ]; then
            cpu_cores=1
            log "CPU限制不足1核，调整为1核"
        fi

        # GC相关优化参数
        JVM_GC_ARGS="-XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:+UseStringDeduplication"
        AUTO_JVM_ARGS="$AUTO_JVM_ARGS $JVM_GC_ARGS"

        # 并行GC线程数设置（基于CPU核心数）
        local gc_threads=$cpu_cores
        if [ "$gc_threads" -gt 8 ]; then
            gc_threads=8  # 限制最大GC线程数
        fi

        local conc_gc_threads=$(echo "scale=0; ($gc_threads + 3) / 4" | bc)
        if [ "$conc_gc_threads" -lt 1 ]; then
            conc_gc_threads=1
        fi

        JVM_PARALLEL_ARGS="-XX:ParallelGCThreads=${gc_threads} -XX:ConcGCThreads=${conc_gc_threads}"
        AUTO_JVM_ARGS="$AUTO_JVM_ARGS $JVM_PARALLEL_ARGS"

        # 性能优化参数
        JVM_PERFORMANCE_ARGS="-XX:+AggressiveOpts -XX:+OptimizeStringConcat -XX:+UseCompressedOops"
        AUTO_JVM_ARGS="$AUTO_JVM_ARGS $JVM_PERFORMANCE_ARGS"

        # JIT编译优化
        JVM_JIT_ARGS="-XX:+TieredCompilation -XX:TieredStopAtLevel=4"
        AUTO_JVM_ARGS="$AUTO_JVM_ARGS $JVM_JIT_ARGS"

        log "CPU限制配置: 核心数=${cpu_cores}, GC线程=${gc_threads}, 并发GC线程=${conc_gc_threads}"
    fi

    # 诊断和监控参数（仅在有资源限制时添加）
    if [ "$DETECTED_MEMORY_BYTES" -gt 0 ] || [ "$DETECTED_CPU_CORES" -gt 0 ]; then
        JVM_DIAGNOSTIC_ARGS="-XX:+PrintGCDetails -XX:+PrintGCTimeStamps -XX:+PrintGCApplicationStoppedTime -Xloggc:/app/logs/gc.log -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=5 -XX:GCLogFileSize=10M"
        AUTO_JVM_ARGS="$AUTO_JVM_ARGS $JVM_DIAGNOSTIC_ARGS"
    fi

    if [ -n "$AUTO_JVM_ARGS" ]; then
        log "自动生成的JVM参数:$AUTO_JVM_ARGS"
    else
        log "未探测到资源限制，不自动配置JVM参数"
    fi
}

# 检查是否为Java原生参数（需要直接透传的参数）
is_java_native_arg() {
    local arg="$1"
    case "$arg" in
        -version|-showversion|-help|-?|-X|-XX:+PrintFlagsFinal|-XX:+PrintGCDetails|\
        -server|-client|-d32|-d64|-hotspot|-jrockit|-cp|-classpath)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# 检查用户参数，如果是Java原生查询参数，直接执行并退出
check_and_handle_native_args() {
    local args=("$@")
    
    # 检查是否包含需要立即执行的Java原生参数
    for arg in "${args[@]}"; do
        if is_java_native_arg "$arg"; then
            log "检测到Java原生参数 '$arg'，直接执行java命令"
            log "执行命令: java $*"
            exec java "$@"
        fi
    done
}

# 解析环境变量和命令行参数
parse_arguments() {
    # JAR路径处理
    DETECTED_JAR_PATH=""
    
    # 检查环境变量
    if [ -n "${JAR_PATH:-}" ]; then
        DETECTED_JAR_PATH="$JAR_PATH"
        log "从环境变量获取JAR路径: $DETECTED_JAR_PATH"
    fi

    # 解析命令行参数
    local args=("$@")
    local final_args=()
    local i=0

    while [ $i -lt ${#args[@]} ]; do
        case "${args[$i]}" in
            -jar)
                if [ $((i + 1)) -lt ${#args[@]} ]; then
                    DETECTED_JAR_PATH="${args[$((i + 1))]}"
                    log "从命令行参数获取JAR路径: $DETECTED_JAR_PATH"
                    # 跳过-jar和jar路径参数，不添加到final_args
                    i=$((i + 2))
                    continue
                else
                    log "错误: -jar 参数后缺少JAR文件路径"
                    exit 1
                fi
                ;;
            *)
                final_args+=("${args[$i]}")
                ;;
        esac
        i=$((i+1))
    done

    # 如果没有通过环境变量或命令行指定JAR路径，检查默认路径
    if [ -z "$DETECTED_JAR_PATH" ]; then
        if [ -f "$DEFAULT_JAR_PATH" ]; then
            DETECTED_JAR_PATH="$DEFAULT_JAR_PATH"
            log "探测到默认JAR文件: $DETECTED_JAR_PATH"
        else
            log "未指定JAR路径且默认路径不存在，将以普通java命令启动"
        fi
    fi

    # 保存剩余的用户参数
    USER_ARGS=("${final_args[@]}")
}

# 合并JVM参数（处理优先级：命令行 > 环境变量 > 自动探测）
merge_jvm_args() {
    # 用于参数去重的关联数组
    declare -A param_map
    local non_jvm_args=()

    # 1. 首先添加自动探测的JVM参数
    if [ -n "$AUTO_JVM_ARGS" ]; then
        local auto_args_array=()
        read -ra auto_args_array <<< "$AUTO_JVM_ARGS"
        for arg in "${auto_args_array[@]}"; do
            if [[ "$arg" =~ ^-X ]] || [[ "$arg" =~ ^-XX: ]] || [[ "$arg" =~ ^-D ]]; then
                local key=$(echo "$arg" | sed 's/=.*$//' | sed 's/[0-9]*[mMgGkK]*$//')
                param_map["$key"]="$arg"
            fi
        done
    fi

    # 2. 然后添加环境变量JVM参数（覆盖相同的key）
    if [ -n "${JAVA_OPTS:-}" ]; then
        if [ -n "${JVM_ARGS:-}" ]; then
            JVM_ARGS="$JAVA_OPTS $JVM_ARGS"
        else
            JVM_ARGS=${JAVA_OPTS}
        fi
    fi
    if [ -n "${JVM_ARGS:-}" ]; then
        log "环境变量JVM参数: $JVM_ARGS"
        local env_args_array=()
        read -ra env_args_array <<< "$JVM_ARGS"
        for arg in "${env_args_array[@]}"; do
            if [[ "$arg" =~ ^-X ]] || [[ "$arg" =~ ^-XX: ]] || [[ "$arg" =~ ^-D ]]; then
                local key=$(echo "$arg" | sed 's/=.*$//' | sed 's/[0-9]*[mMgGkK]*$//')
                if [ -n "${param_map[$key]:-}" ]; then
                    log "环境变量覆盖参数: $key -> $arg"
                fi
                param_map["$key"]="$arg"
            else
                non_jvm_args+=("$arg")
            fi
        done
    fi

    # 3. 最后添加用户命令行JVM参数（最高优先级）
    for arg in "${USER_ARGS[@]}"; do
        if [[ "$arg" =~ ^-X ]] || [[ "$arg" =~ ^-XX: ]] || [[ "$arg" =~ ^-D ]]; then
            local key=$(echo "$arg" | sed 's/=.*$//' | sed 's/[0-9]*[mMgGkK]*$//')
            if [ -n "${param_map[$key]:-}" ]; then
                log "命令行覆盖参数: $key -> $arg"
            fi
            param_map["$key"]="$arg"
        else
            non_jvm_args+=("$arg")
        fi
    done

    # 构建最终的JVM参数数组
    FINAL_JVM_ARGS=()
    for key in "${!param_map[@]}"; do
        FINAL_JVM_ARGS+=("${param_map[$key]}")
    done

    # 处理JAR参数
    FINAL_JAR_ARGS=()
    if [ -n "$DETECTED_JAR_PATH" ]; then
        if [ -f "$DETECTED_JAR_PATH" ]; then
            FINAL_JAR_ARGS=("-jar" "$DETECTED_JAR_PATH")
            log "将使用JAR文件: $DETECTED_JAR_PATH"
        else
            log "错误: 指定的JAR文件不存在: $DETECTED_JAR_PATH"
            exit 1
        fi
    fi

    # 非JVM参数
    FINAL_NON_JVM_ARGS=("${non_jvm_args[@]}")

    if [ ${#FINAL_JVM_ARGS[@]} -gt 0 ]; then
        log "最终JVM参数: ${FINAL_JVM_ARGS[*]}"
    else
        log "未配置JVM参数"
    fi
}

# 验证Java环境
verify_java() {
    if ! command -v java >/dev/null 2>&1; then
        log "错误: 未找到java命令"
        exit 1
    fi

    local java_version=$(java -version 2>&1 | head -n1)
    log "Java版本: $java_version"
}

# 构建并执行最终命令
execute_java_command() {
    # 构建完整的命令参数数组
    local final_command=("java")
    
    # 添加JVM参数
    if [ ${#FINAL_JVM_ARGS[@]} -gt 0 ]; then
        final_command+=("${FINAL_JVM_ARGS[@]}")
    fi
    
    # 添加JAR参数
    if [ ${#FINAL_JAR_ARGS[@]} -gt 0 ]; then
        final_command+=("${FINAL_JAR_ARGS[@]}")
    fi
    
    # 添加非JVM参数
    if [ ${#FINAL_NON_JVM_ARGS[@]} -gt 0 ]; then
        final_command+=("${FINAL_NON_JVM_ARGS[@]}")
    fi

    log "执行命令: ${final_command[*]}"
    
    # 执行Java命令
    exec "${final_command[@]}"
}

# 主函数
main() {
    log "启动 JDK 8u202 容器 (基于 AlmaLinux 9.6)..."

    verify_java
    
    # 首先检查是否为Java原生参数，如果是则直接执行
    check_and_handle_native_args "$@"
    
    # 继续正常的参数解析和资源探测流程
    detect_cgroup_resources
    generate_jvm_args
    parse_arguments "$@"
    merge_jvm_args

    log "准备启动应用..."
    if [ "$DETECTED_CPU_CORES" -gt 0 ]; then
        log "CPU核心数: $DETECTED_CPU_CORES"
    fi
    if [ "$DETECTED_MEMORY_MB" -gt 0 ]; then
        log "内存限制: $DETECTED_MEMORY_MB MB"
    fi

    # 执行Java命令
    execute_java_command
}

# 捕获信号并优雅关闭
trap 'log "收到终止信号，正在关闭应用..."; exit 0' SIGTERM SIGINT

# 执行主函数
main "$@"
