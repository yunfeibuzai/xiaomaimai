#!/bin/bash
echo -e "${CYAN}📦 当前服务器安装的模组 (.jar) 列表：${NC}"
docker exec -i "$CONTAINER_NAME" ls -lh /data/mods/ 2>/dev/null | grep ".jar" || echo -e "${YELLOW}⚠️ 未发现模组，可能当前为原版环境或暂未上传模组。${NC}"
