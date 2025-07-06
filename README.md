自用clash规则，未包含节点信息。
# VPS部署节部方式

# DOCKER部署 cf端口2733
docker run -d \
--name seven \
--restart unless-stopped \
-e uuid=uuid \
-e token=  \
-e domain=域名 \
7techlife/seven && docker logs -f seven

# 命令部署
vlpt="" vmpt="端口" hypt="" tupt="" argo="y" agn="域名" agk="token" bash <(curl -Ls https://raw.githubusercontent.com/yonggekkk/argosb/main/argosb.sh)
