#!/bin/bash
# ==========================================
# Minecraft Docker 自动化运维助手
# 依赖: Docker, itzg/minecraft-server 镜像
# ==========================================

# 设置你的容器名称
CONTAINER_NAME="mcserver"

function show_menu() {
    clear
    echo "============================="
    echo "   Minecraft 自动化运维助手"
    echo "============================="
    echo "1. 📜 查看实时日志 (按 Ctrl+C 返回)"
    echo "2. 🔄 重启服务器"
    echo "3. 📦 一键备份存档 (防炸服/坏档)"
    echo "4. 📊 查看服务器占用 (按 Ctrl+C 返回)"
    echo "5. ⌨️  向后台发送指令 (如白名单/踢人/给OP)"
    echo "0. ❌ 退出"
    echo "============================="
}

function view_logs() {
    echo "👉 正在输出日志，按 Ctrl + C 退出查看"
    sleep 1
    docker logs -f "$CONTAINER_NAME"
}

function restart_server() {
    echo "⏳ 正在重启服务器，请稍候..."
    docker restart "$CONTAINER_NAME"
    echo "✅ 服务器正在启动，可使用功能 1 查看启动进度！"
}

function backup_world() {
    DATE=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="mc_world_backup_$DATE.tar.gz"
    echo "⏳ 正在备份存档，请稍候..."
    # 提取容器内的 /data/world 目录打包到宿主机的当前目录
    docker exec -i "$CONTAINER_NAME" tar -czf - /data/world > "$BACKUP_FILE"
    echo "✅ 备份成功！文件已保存为当前目录下的: $BACKUP_FILE"
}

function view_stats() {
    echo "👉 正在监控资源，按 Ctrl + C 退出查看"
    sleep 1
    docker stats "$CONTAINER_NAME"
}

function send_command() {
    echo "💡 提示: 赋予管理员请输入 op 玩家名 (例如: op xiaomaimai)"
    read -p "👉 请输入指令: " cmd
    if [ -n "$cmd" ]; then
        docker exec -i "$CONTAINER_NAME" rcon-cli $cmd
        echo "✅ 指令 [$cmd] 已发送！"
    else
        echo "⚠️ 指令不能为空"
    fi
}

# 循环显示菜单
while true; do
    show_menu
    read -p "请输入序号执行操作: " num
    case $num in
        1) view_logs ;;
        2) restart_server ; read -n 1 -s -r -p "按任意键返回菜单..." ;;
        3) backup_world ; read -n 1 -s -r -p "按任意键返回菜单..." ;;
        4) view_stats ;;
        5) send_command ; read -n 1 -s -r -p "按任意键返回菜单..." ;;
        0) echo "👋 拜拜！" ; exit 0 ;;
        *) echo "⚠️ 无效输入，请重新输入!" ; sleep 1 ;;
    esac
done
