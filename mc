#!/bin/bash
# ==========================================
# Minecraft Docker 高级自动化运维助手 3.0
# 依赖: Docker, itzg/minecraft-server 镜像
# 项目地址: https://github.com/yunfeibuzai/xiaomaimai
# ==========================================

# 基础配置
CONTAINER_NAME="mcserver"
# 自动更新时抓取的 Raw 代码源地址
SCRIPT_URL="https://raw.githubusercontent.com/yunfeibuzai/xiaomaimai/main/mc"

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # 清除颜色

# 状态检测
function check_status() {
    if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
        STATUS="${GREEN}[运行中 / Online]${NC}"
    elif [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
        STATUS="${RED}[已停止 / Offline]${NC}"
    else
        STATUS="${YELLOW}[未创建 / Not Found]${NC}"
    fi
}

# 显示菜单
function show_menu() {
    clear
    check_status
    echo -e "${CYAN}=======================================${NC}"
    echo -e "${GREEN}    🧊 Minecraft 自动化运维助手 Pro${NC}"
    echo -e "${CYAN}=======================================${NC}"
    echo -e " 🖥️  服务器状态: ${STATUS}"
    echo -e " 🏷️  容器名称  : ${YELLOW}${CONTAINER_NAME}${NC}"
    echo -e "${CYAN}---------------------------------------${NC}"
    echo -e "${BLUE}▶ 基础控制 (Control)${NC}"
    echo -e "  ${GREEN}1.${NC} 🟢 启动服务器"
    echo -e "  ${RED}2.${NC} 🔴 停止服务器"
    echo -e "  ${YELLOW}3.${NC} 🔄 重启服务器"
    echo -e "${BLUE}▶ 监控与管理 (Monitor & Manage)${NC}"
    echo -e "  ${CYAN}4.${NC} 📜 查看实时日志 (Ctrl+C 返回)"
    echo -e "  ${CYAN}5.${NC} 📊 查看性能占用 (CPU/内存)"
    echo -e "  ${CYAN}6.${NC} ⌨️  发送单条指令 (如: op, whitelist)"
    echo -e "  ${CYAN}7.${NC} 💬 进入交互控制台 (连续输入模式)"
    echo -e "${BLUE}▶ 数据与模组 (Data & Mods)${NC}"
    echo -e "  ${YELLOW}8.${NC} 📦 一键完整备份 (世界存档)"
    echo -e "  ${YELLOW}9.${NC} 🧩 查看已安装模组 (Mods列表)"
    echo -e "  ${YELLOW}10.${NC}📥 交互式添加模组 (在线下载)"
    echo -e "${BLUE}▶ 系统功能 (System)${NC}"
    echo -e "  ${CYAN}11.${NC}🚀 从 GitHub 更新本运维脚本"
    echo -e "${CYAN}---------------------------------------${NC}"
    echo -e "  ${RED}0.${NC} ❌ 退出面板"
    echo -e "${CYAN}=======================================${NC}"
}

# --------- 核心功能模块 ---------

function start_server() {
    echo -e "${YELLOW}⏳ 正在启动服务器...${NC}"
    docker start "$CONTAINER_NAME"
    echo -e "${GREEN}✅ 启动命令已发送！请使用选项 4 查看开服进度。${NC}"
}

function stop_server() {
    echo -e "${YELLOW}⏳ 正在安全保存世界并关闭服务器...${NC}"
    docker stop "$CONTAINER_NAME"
    echo -e "${GREEN}✅ 服务器已成功停止。${NC}"
}

function interactive_console() {
    echo -e "${CYAN}👉 即将进入游戏后台交互模式。${NC}"
    echo -e "${YELLOW}⚠️  提示: 输入 exit 或按 Ctrl+C 退出此模式，且【不会】导致服务器关机。${NC}"
    sleep 2
    docker exec -it "$CONTAINER_NAME" rcon-cli
}

function list_mods() {
    echo -e "${CYAN}📦 当前服务器安装的模组 (.jar) 列表：${NC}"
    docker exec -i "$CONTAINER_NAME" ls -lh /data/mods/ 2>/dev/null | grep ".jar" || echo -e "${YELLOW}⚠️ 未发现模组，可能当前为原版环境或暂未上传模组。${NC}"
}

function backup_world() {
    DATE=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="mc_world_backup_$DATE.tar.gz"
    echo -e "${YELLOW}⏳ 正在压缩打包世界数据，请稍候...${NC}"
    docker exec -i "$CONTAINER_NAME" tar -czf - /data/world > "$BACKUP_FILE"
    echo -e "${GREEN}✅ 备份大功告成！${NC}"
    echo -e "📂 存档文件已保存在当前目录: ${BLUE}$BACKUP_FILE${NC}"
}

function send_command() {
    echo -e "${YELLOW}💡 提示: 给自己管理权限请输入 op 你的ID${NC}"
    read -p "👉 请输入完整指令: " cmd
    if [ -n "$cmd" ]; then
        docker exec -i "$CONTAINER_NAME" rcon-cli $cmd
        echo -e "${GREEN}✅ 指令已送达！${NC}"
    else
        echo -e "${RED}⚠️ 指令不能为空${NC}"
    fi
}

function add_mod() {
    echo -e "${CYAN}🧩 交互式下载并安装模组${NC}"
    read -p "👉 请输入你要保存的模组文件名 (例如 jei-1.20.1.jar): " mod_name
    if [ -z "$mod_name" ]; then
        echo -e "${RED}⚠️ 文件名不能为空！${NC}"
        return
    fi
    # 自动补全 .jar 后缀
    if [[ "$mod_name" != *.jar ]]; then
        mod_name="${mod_name}.jar"
    fi

    read -p "👉 请输入该模组的直链下载地址 (可以是被解析出的下载直链): " mod_url
    if [ -z "$mod_url" ]; then
        echo -e "${RED}⚠️ 下载链接不能为空！${NC}"
        return
    fi

    echo -e "${YELLOW}⏳ 正在极速下载 ${mod_name} 到服务器，请稍候...${NC}"
    
    # 直接在容器内部下载到 /data/mods 目录
    docker exec -i "$CONTAINER_NAME" sh -c "mkdir -p /data/mods && wget -q -O '/data/mods/$mod_name' '$mod_url'"
    
    # 验证文件是否下载成功（判断文件大小是否大于0）
    if docker exec -i "$CONTAINER_NAME" test -s "/data/mods/$mod_name"; then
        echo -e "${GREEN}✅ 模组 ${mod_name} 成功下载并部署！${NC}"
        echo -e "${YELLOW}💡 提示：添加或删除模组后，你需要重启服务器 (菜单选项 3) 才能生效。${NC}"
    else
        echo -e "${RED}⚠️ 下载失败，请检查下载链接是否真实有效，或网络是否通畅。${NC}"
        docker exec -i "$CONTAINER_NAME" rm -f "/data/mods/$mod_name" 2>/dev/null
    fi
}

function update_script() {
    echo -e "${YELLOW}⏳ 正在从你的 GitHub 仓库获取最新版本的脚本...${NC}"
    if curl -sSL "$SCRIPT_URL" -o /usr/local/bin/mc; then
        chmod +x /usr/local/bin/mc
        echo -e "${GREEN}✅ 运维脚本已成功热更新至最新版！${NC}"
        echo -e "${CYAN}👉 即将自动重新加载助手...${NC}"
        sleep 2
        exec /usr/local/bin/mc
    else
        echo -e "${RED}⚠️ 更新失败！请检查你的 GitHub 仓库地址是否正确或服务器网络连接。${NC}"
    fi
}

# 主循环
while true; do
    show_menu
    read -p "🎯 请输入序号执行操作: " num
    case $num in
        1) start_server ; read -n 1 -s -r -p "按任意键返回菜单..." ;;
        2) stop_server ; read -n 1 -s -r -p "按任意键返回菜单..." ;;
        3) 
           echo -e "${YELLOW}⏳ 正在重启...${NC}"
           docker restart "$CONTAINER_NAME"
           echo -e "${GREEN}✅ 重启成功！${NC}"
           read -n 1 -s -r -p "按任意键返回菜单..." ;;
        4) 
           echo -e "${CYAN}👉 正在输出日志，按 Ctrl + C 退出日志查看${NC}"
           sleep 1
           docker logs -f "$CONTAINER_NAME" ;;
        5) 
           echo -e "${CYAN}👉 正在监控资源占用，按 Ctrl + C 退出监控${NC}"
           sleep 1
           docker stats "$CONTAINER_NAME" ;;
        6) send_command ; read -n 1 -s -r -p "按任意键返回菜单..." ;;
        7) interactive_console ;;
        8) backup_world ; read -n 1 -s -r -p "按任意键返回菜单..." ;;
        9) list_mods ; read -n 1 -s -r -p "按任意键返回菜单..." ;;
        10) add_mod ; read -n 1 -s -r -p "按任意键返回菜单..." ;;
        11) update_script ;;
        0) echo -e "${GREEN}👋 感谢使用，拜拜！${NC}" ; exit 0 ;;
        *) echo -e "${RED}⚠️ 无效输入，请查验后重新输入!${NC}" ; sleep 1 ;;
    esac
done
