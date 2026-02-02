#!/bin/bash

# JDK 8 容器启动脚本
# 支持 cgroup v1/v2 自动探测与 JVM 参数优化

set -e

DEFAULT_JAR_PATH="/app/app.jar"
DEFAULT_HEAP_MAX_PERCENT=75
DEFAULT_HEAP_MIN_PERCENT=25

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ENTRYPOINT] $1"
}

# 检测 JDK 版本
detect_jdk_version() {
    if ! command -v java >/dev/null 2>&1; then
        log "错误: 未找到 java 命令"
        exit 1
    fi

    local java_version_output=$(java -version 2>&1 | head -n1)
    log "Java 版本: $java_version_output"

    # 提取版本号 (例如: 1.8.0_202 -> 202, 1.8.0_472 -> 472)
    local version_number=$(echo "$java_version_output" | grep -oP '1\.8\.0_\K[0-9]+' || echo "0")
    
    export DETECTED_JDK_VERSION=$version_number
    
    # 判断是否支持 cgroup v2 (8u372+ 支持)
    if [ "$version_number" -ge 372 ]; then
        export SUPPORTS_CGROUPV2=true
    else
        export SUPPORTS_CGROUPV2=false
    fi
}

# 探测 cgroup 版本和资源限制
detect_cgroup_resources() {
    local cpu_cores=0
    local memory_bytes=0
    local cgroup_version=""

    if [ -f /sys/fs/cgroup/cgroup.controllers ]; then
        cgroup_version="v2"

        # cgroup v2 CPU 限制
        if [ -f /sys/fs/cgroup/cpu.max ]; then
            local cpu_max=$(cat /sys/fs/cgroup/cpu.max 2>/dev/null || echo "max")
            if [ "$cpu_max" != "max" ] && [[ $cpu_max =~ ^[0-9]+[[:space:]]+[0-9]+$ ]]; then
                local cpu_quota=$(echo $cpu_max | awk '{print $1}')
                local cpu_period=$(echo $cpu_max | awk '{print $2}')
                if [ "$cpu_quota" -gt 0 ] && [ "$cpu_period" -gt 0 ]; then
                    # 使用 bc 进行浮点运算并向上取整
                    cpu_cores=$(echo "scale=0; ($cpu_quota + $cpu_period - 1) / $cpu_period" | bc 2>/dev/null || echo "0")
                    if [ "$cpu_cores" -gt 0 ]; then
                        log "探测到 CPU 限制: ${cpu_cores} 核"
                    fi
                fi
            fi
        fi

        # cgroup v2 内存限制
        if [ -f /sys/fs/cgroup/memory.max ]; then
            local mem_max=$(cat /sys/fs/cgroup/memory.max 2>/dev/null || echo "max")
            if [ "$mem_max" != "max" ] && [[ $mem_max =~ ^[0-9]+$ ]] && [ "$mem_max" -gt 0 ]; then
                memory_bytes=$mem_max
                log "探测到内存限制: $((memory_bytes / 1024 / 1024)) MB"
            fi
        fi

    elif [ -d /sys/fs/cgroup/cpu ] || [ -d /sys/fs/cgroup/memory ]; then
        cgroup_version="v1"

        # cgroup v1 CPU 限制
        local cpu_quota_file="/sys/fs/cgroup/cpu/cpu.cfs_quota_us"
        local cpu_period_file="/sys/fs/cgroup/cpu/cpu.cfs_period_us"
        if [ -f "$cpu_quota_file" ] && [ -f "$cpu_period_file" ]; then
            local cpu_quota=$(cat $cpu_quota_file 2>/dev/null || echo "-1")
            local cpu_period=$(cat $cpu_period_file 2>/dev/null || echo "100000")
            if [ "$cpu_quota" -gt 0 ] && [ "$cpu_period" -gt 0 ]; then
                cpu_cores=$(echo "scale=0; ($cpu_quota + $cpu_period - 1) / $cpu_period" | bc 2>/dev/null || echo "0")
                if [ "$cpu_cores" -gt 0 ]; then
                    log "探测到 CPU 限制: ${cpu_cores} 核"
                fi
            fi
        fi

        # cgroup v1 内存限制
        local mem_limit_file="/sys/fs/cgroup/memory/memory.limit_in_bytes"
        if [ -f "$mem_limit_file" ]; then
            local mem_limit=$(cat $mem_limit_file 2>/dev/null || echo "0")
            if [ "$mem_limit" -gt 0 ] && [ "$mem_limit" -lt 9223372036854775807 ]; then
                memory_bytes=$mem_limit
                log "探测到内存限制: $((memory_bytes / 1024 / 1024)) MB"
            fi
        fi
    else
        log "未检测到 cgroup,不自动配置资源参数"
    fi

    export DETECTED_CPU_CORES=$cpu_cores
    export DETECTED_MEMORY_BYTES=$memory_bytes
    export DETECTED_MEMORY_MB=$((memory_bytes / 1024 / 1024))
    export DETECTED_CGROUP_VERSION=$cgroup_version
}

# 生成 JVM 参数
generate_jvm_args() {
    AUTO_JVM_ARGS=""

    # 基础系统参数(优先级最低,允许用户覆盖)
    AUTO_JVM_ARGS="$AUTO_JVM_ARGS -Dfile.encoding=utf-8"
    AUTO_JVM_ARGS="$AUTO_JVM_ARGS -Djava.security.egd=file:/dev/./urandom"
    AUTO_JVM_ARGS="$AUTO_JVM_ARGS -Duser.timezone=Asia/Shanghai"

    local heap_max_percent=${HEAP_MAX_PERCENT:-$DEFAULT_HEAP_MAX_PERCENT}
    local heap_min_percent=${HEAP_MIN_PERCENT:-$DEFAULT_HEAP_MIN_PERCENT}

    # 验证百分比范围 (防止非数字输入)
    if ! [[ "$heap_max_percent" =~ ^[0-9]+$ ]] || [ "$heap_max_percent" -lt 1 ] || [ "$heap_max_percent" -gt 95 ]; then
        log "警告: HEAP_MAX_PERCENT ($heap_max_percent) 无效,使用默认值 $DEFAULT_HEAP_MAX_PERCENT"
        heap_max_percent=$DEFAULT_HEAP_MAX_PERCENT
    fi
    if ! [[ "$heap_min_percent" =~ ^[0-9]+$ ]] || [ "$heap_min_percent" -lt 1 ] || [ "$heap_min_percent" -gt "$heap_max_percent" ]; then
        log "警告: HEAP_MIN_PERCENT ($heap_min_percent) 无效,使用默认值 $DEFAULT_HEAP_MIN_PERCENT"
        heap_min_percent=$DEFAULT_HEAP_MIN_PERCENT
    fi

    # cgroup v2 + 低版本 JDK 兼容处理
    # 只有在 cgroup v2 环境且 JDK 不支持时才禁用容器自动探测
    if [ "$DETECTED_CGROUP_VERSION" = "v2" ] && [ "$SUPPORTS_CGROUPV2" = "false" ]; then
        log "检测到 cgroup v2 但 JDK 版本不支持,禁用容器自动探测"
        AUTO_JVM_ARGS="$AUTO_JVM_ARGS -XX:-UseContainerSupport"
    fi

    # 内存配置
    if [ "$DETECTED_MEMORY_BYTES" -gt 0 ]; then
        local max_heap_mb=$((DETECTED_MEMORY_MB * heap_max_percent / 100))
        local min_heap_mb=$((DETECTED_MEMORY_MB * heap_min_percent / 100))
        
        if [ "$min_heap_mb" -lt 8 ]; then
            heap_min_percent=" N/A "
            min_heap_mb=8
        fi

        if [ "$max_heap_mb" -lt "$min_heap_mb" ]; then
            heap_max_percent=" N/A "
            max_heap_mb="$min_heap_mb"
        fi

        AUTO_JVM_ARGS="$AUTO_JVM_ARGS -Xmx${max_heap_mb}m -Xms${min_heap_mb}m"
        AUTO_JVM_ARGS="$AUTO_JVM_ARGS -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/app/logs/"
        AUTO_JVM_ARGS="$AUTO_JVM_ARGS -XX:+ExitOnOutOfMemoryError"

        log "内存配置: 最大堆=${max_heap_mb}MB (${heap_max_percent}%), 最小堆=${min_heap_mb}MB (${heap_min_percent}%)"
    fi

    # CPU 配置
    if [ "$DETECTED_CPU_CORES" -gt 0 ]; then
        local cpu_cores=$DETECTED_CPU_CORES
        
        # CPU 不足 1 核按 1 核计算
        if [ "$cpu_cores" -lt 1 ]; then
            cpu_cores=1
            log "CPU 限制不足 1 核,调整为 1 核"
        fi

        # 显式设置处理器数量,确保 Runtime.availableProcessors() 正确
        # 对于不支持 cgroup v2 的版本,这是唯一的 CPU 限制方式
        AUTO_JVM_ARGS="$AUTO_JVM_ARGS -XX:ActiveProcessorCount=${cpu_cores}"

        # G1GC 配置
        AUTO_JVM_ARGS="$AUTO_JVM_ARGS -XX:+UseG1GC -XX:MaxGCPauseMillis=200"
        AUTO_JVM_ARGS="$AUTO_JVM_ARGS -XX:+UseStringDeduplication"

        # GC 线程配置
        local gc_threads=$cpu_cores
        if [ "$gc_threads" -gt 8 ]; then
            gc_threads=8
        fi

        local conc_gc_threads=$(echo "scale=0; ($gc_threads + 3) / 4" | bc)
        if [ "$conc_gc_threads" -lt 1 ]; then
            conc_gc_threads=1
        fi

        AUTO_JVM_ARGS="$AUTO_JVM_ARGS -XX:ParallelGCThreads=${gc_threads}"
        AUTO_JVM_ARGS="$AUTO_JVM_ARGS -XX:ConcGCThreads=${conc_gc_threads}"

        # 性能优化
        AUTO_JVM_ARGS="$AUTO_JVM_ARGS -XX:+OptimizeStringConcat -XX:+UseCompressedOops"
        AUTO_JVM_ARGS="$AUTO_JVM_ARGS -XX:+TieredCompilation -XX:TieredStopAtLevel=4"

        log "CPU 配置: 核心数=${cpu_cores}, GC 线程=${gc_threads}, 并发 GC 线程=${conc_gc_threads}"
    fi

    # GC 日志配置
    if [ "$DETECTED_MEMORY_BYTES" -gt 0 ] || [ "$DETECTED_CPU_CORES" -gt 0 ]; then
        # 确保日志目录存在
        if [ ! -d "/app/logs" ]; then
            mkdir -p /app/logs 2>/dev/null || log "警告: 无法创建日志目录 /app/logs"
        fi
        
        if [ -d "/app/logs" ] && [ -w "/app/logs" ]; then
            AUTO_JVM_ARGS="$AUTO_JVM_ARGS -XX:+PrintGCDetails -XX:+PrintGCDateStamps"
            AUTO_JVM_ARGS="$AUTO_JVM_ARGS -Xloggc:/app/logs/gc.log"
            AUTO_JVM_ARGS="$AUTO_JVM_ARGS -XX:+UseGCLogFileRotation"
            AUTO_JVM_ARGS="$AUTO_JVM_ARGS -XX:NumberOfGCLogFiles=5 -XX:GCLogFileSize=10M"
        else
            log "警告: 日志目录不可写,跳过 GC 日志配置"
        fi
    fi

    if [ -n "$AUTO_JVM_ARGS" ]; then
        log "自动生成 JVM 参数:$AUTO_JVM_ARGS"
    fi
}

# 检查 Java 原生参数
is_java_native_arg() {
    local arg="$1"
    case "$arg" in
        -version|-showversion|-help|-?|-X|-XX:+PrintFlagsFinal|\
        -XshowSettings*|-server|-client|-cp|-classpath)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

check_and_handle_native_args() {
    for arg in "$@"; do
        if is_java_native_arg "$arg"; then
            log "检测到 Java 原生参数,直接执行: java $*"
            exec java "$@"
        fi
    done
}

# 解析参数
parse_arguments() {
    DETECTED_JAR_PATH=""

    if [ -n "${JAR_PATH:-}" ]; then
        DETECTED_JAR_PATH="$JAR_PATH"
        log "从环境变量获取 JAR 路径: $DETECTED_JAR_PATH"
    fi

    local args=("$@")
    local final_args=()
    local i=0

    while [ $i -lt ${#args[@]} ]; do
        case "${args[$i]}" in
            -jar)
                if [ $((i + 1)) -lt ${#args[@]} ]; then
                    DETECTED_JAR_PATH="${args[$((i + 1))]}"
                    log "从命令行获取 JAR 路径: $DETECTED_JAR_PATH"
                    i=$((i + 2))
                    continue
                else
                    log "错误: -jar 参数后缺少 JAR 文件路径"
                    exit 1
                fi
                ;;
            *)
                final_args+=("${args[$i]}")
                ;;
        esac
        i=$((i+1))
    done

    if [ -z "$DETECTED_JAR_PATH" ] && [ -f "$DEFAULT_JAR_PATH" ]; then
        DETECTED_JAR_PATH="$DEFAULT_JAR_PATH"
        log "使用默认 JAR 文件: $DETECTED_JAR_PATH"
    fi

    USER_ARGS=("${final_args[@]}")
}

# 合并 JVM 参数 (优先级: 命令行 > 环境变量 > 自动探测)
merge_jvm_args() {
    declare -A param_map
    local non_jvm_args=()

    # 1. 自动探测参数 (最低优先级)
    if [ -n "$AUTO_JVM_ARGS" ]; then
        local auto_args_array=()
        read -ra auto_args_array <<< "$AUTO_JVM_ARGS"
        for arg in "${auto_args_array[@]}"; do
            if [[ "$arg" =~ ^-X ]] || [[ "$arg" =~ ^-XX: ]] || [[ "$arg" =~ ^-D ]]; then
                # 提取参数键进行去重
                local key=$(echo "$arg" | sed 's/=.*$//' | sed 's/[0-9]*[mMgGkK]*$//')
                param_map["$key"]="$arg"
            fi
        done
    fi

    # 2. 环境变量参数 (中优先级)
    if [ -n "${JAVA_OPTS:-}" ]; then
        JVM_ARGS="${JAVA_OPTS}${JVM_ARGS:+ $JVM_ARGS}"
    fi
    if [ -n "${JVM_ARGS:-}" ]; then
        log "环境变量 JVM 参数: $JVM_ARGS"
        local env_args_array=()
        read -ra env_args_array <<< "$JVM_ARGS"
        for arg in "${env_args_array[@]}"; do
            # 跳过空参数
            [ -z "$arg" ] && continue
            
            if [[ "$arg" =~ ^-X ]] || [[ "$arg" =~ ^-XX: ]] || [[ "$arg" =~ ^-D ]]; then
                local key=$(echo "$arg" | sed 's/=.*$//' | sed 's/[0-9]*[mMgGkK]*$//')
                if [ -n "${param_map[$key]:-}" ] && [ "${param_map[$key]}" != "$arg" ]; then
                    log "环境变量覆盖: $key -> $arg"
                fi
                param_map["$key"]="$arg"
            else
                non_jvm_args+=("$arg")
            fi
        done
    fi

    # 3. 命令行参数 (最高优先级)
    for arg in "${USER_ARGS[@]}"; do
        [ -z "$arg" ] && continue
        
        if [[ "$arg" =~ ^-X ]] || [[ "$arg" =~ ^-XX: ]] || [[ "$arg" =~ ^-D ]]; then
            local key=$(echo "$arg" | sed 's/=.*$//' | sed 's/[0-9]*[mMgGkK]*$//')
            if [ -n "${param_map[$key]:-}" ] && [ "${param_map[$key]}" != "$arg" ]; then
                log "命令行覆盖: $key -> $arg"
            fi
            param_map["$key"]="$arg"
        else
            non_jvm_args+=("$arg")
        fi
    done

    FINAL_JVM_ARGS=()
    for key in "${!param_map[@]}"; do
        FINAL_JVM_ARGS+=("${param_map[$key]}")
    done

    FINAL_JAR_ARGS=()
    if [ -n "$DETECTED_JAR_PATH" ]; then
        if [ -f "$DETECTED_JAR_PATH" ]; then
            FINAL_JAR_ARGS=("-jar" "$DETECTED_JAR_PATH")
        else
            log "错误: JAR 文件不存在: $DETECTED_JAR_PATH"
            exit 1
        fi
    fi

    FINAL_NON_JVM_ARGS=("${non_jvm_args[@]}")

    if [ ${#FINAL_JVM_ARGS[@]} -gt 0 ]; then
        log "最终 JVM 参数: ${FINAL_JVM_ARGS[*]}"
    fi
}

# 执行 Java 命令
execute_java_command() {
    local final_command=("java")

    if [ ${#FINAL_JVM_ARGS[@]} -gt 0 ]; then
        final_command+=("${FINAL_JVM_ARGS[@]}")
    fi

    if [ ${#FINAL_JAR_ARGS[@]} -gt 0 ]; then
        final_command+=("${FINAL_JAR_ARGS[@]}")
    fi

    if [ ${#FINAL_NON_JVM_ARGS[@]} -gt 0 ]; then
        final_command+=("${FINAL_NON_JVM_ARGS[@]}")
    fi

    log "执行命令: ${final_command[*]}"
    exec "${final_command[@]}"
}

# 主函数
main() {
    detect_jdk_version

    check_and_handle_native_args "$@"

    detect_cgroup_resources
    generate_jvm_args
    parse_arguments "$@"
    merge_jvm_args

    log "准备启动应用"
    [ -n "$DETECTED_CGROUP_VERSION" ] && log "Cgroup: $DETECTED_CGROUP_VERSION"
    [ "$DETECTED_CPU_CORES" -gt 0 ] && log "CPU: $DETECTED_CPU_CORES 核"
    [ "$DETECTED_MEMORY_MB" -gt 0 ] && log "内存: $DETECTED_MEMORY_MB MB"

    execute_java_command
}

trap 'log "收到终止信号"; exit 0' SIGTERM SIGINT

main "$@"
