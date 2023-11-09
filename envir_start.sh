# Variables
CLAIM="\"claim-45od-_aqzWM28cGaeawi\""
PlexData="/mnt/DataDisk1_500G/plex"

# Terminals
sudo apt update
sudo apt-get install docker.io
mkdir ~/netdata
mkdir ~/alist
mkdir ~/plex

docker run -d --name=Portainer \
  -p 9000:9000 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --restart=always \
  6053537/portainer-ce

docker run -d --name=NetData \
  -p 19999:19999 \
  -v ~/netdata/netdataconfig:/etc/netdata \
  -v ~/netdata/netdatalib:/var/lib/netdata \
  -v ~/netdata/netdatacache:/var/cache/netdata \
  -v ~/netdata/passwd:/host/etc/passwd:ro \
  -v ~/netdata/group:/host/etc/group:ro \
  -v ~/netdata/proc:/host/proc:ro \
  -v ~/netdata/sys:/host/sys:ro \
  -v ~/netdata/os-release:/host/etc/os-release:ro \
  --restart unless-stopped \
  --cap-add SYS_PTRACE \
  --security-opt apparmor=unconfined \
  netdata/netdata

docker run -d --restart=always \
  -v ~/alist:/opt/alist/data \
  -p 5244:5244 \
  -e PUID=0 \
  -e PGID=0 \
  -e UMASK=022 \
  --name="Alist" xhofe/alist:latest

docker exec -it Alist ./alist admin | grep password

cd ~/plex

cat << EOF >> docker-compose.yml
version: '2'
services:
  plex:
    container_name: plex
    image: plexinc/pms-docker
    restart: unless-stopped
    ports:
       - 32400:32400/tcp
    #   - 3005:3005/tcp
    #   - 8324:8324/tcp
    #   - 32469:32469/tcp
    #   - 2900:1900/udp
    #   - 32410:32410/udp
    #   - 32412:32412/udp
    #   - 32413:32413/udp
    #   - 32414:32414/udp
    environment:
      - TZ=Asia/Shanghai
      - PLEX_CLAIM=$CLAIM
    volumes:
      - ~/plex/pms-docker/database:/config
      - ~/plex/pms-docker/transcode:/transcode
      - $PlexData:/data
    network_mode: host
EOF

docker-compose up -d

cd ..

git clone https://github.com/overleaf/toolkit.git ./overleaf-toolkit

cd ./overleaf-toolkit

bin/init

bin/up -d

cd ..

docker pull dperson/samba

docker run -it --name samba -p 139:139 -p 445:445 -v /mnt/DataDisk2_4T/Samba:/mount -d dperson/samba -u "zhuoyue;lxd12251026" -s "share;/mount/;yes;no;no;all;user;user" --restart unless-stopped

cat << EOF >> docker-compose.yml
version: "3"
services:
  clash:
    image: dreamacro/clash
    restart: unless-stopped
    volumes:
      - ~/Clash/config:/root/.config/clash
    ports:
      - "7890:7890"
      - "7891:7891/udp"
EOF

docker pull haishanh/yacd

docker run -p 9001:80 -d haishanh/yacd --name "ClashWeb" --restart unless-stopped

# navidrome

mkdir ./navidrome

cat << EOF >> ./navidrome/docker-compose.yml
version: "3"
services:
  navidrome:
    container_name: navidrome
    image: deluan/navidrome:latest
    user: 0:0
    ports:
      - "4533:4533"
    restart: unless-stopped
    environment:
      # Optional: put your config options customization here. Examples:
      ND_SCANSCHEDULE: 1h
      ND_LOGLEVEL: info  
      ND_SESSIONTIMEOUT: 24h
      ND_BASEURL: ""
      ND_ENABLETRANSCODINGCONFIG: "true"
      ND_TRANSCODINGCACHESIZE: "4000M"
      ND_IMAGECACHESIZE: "1000M"
    volumes:
      - "~/navidrome/data:/data"
      - "/mnt/DataDisk2_4T/Music:/music:ro"
EOF

mkdir qbittorrent

docker run -d \
  --name=qbittorrent \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Asia/Shanghai \
  -e WEBUI_PORT=8080 \
  -p 8080:8080 \
  -p 6881:6881 \
  -p 6881:6881/udp \
  -v ~/qbittorrent/config:/config \
  -v /mnt/DataDisk1_6T/Download/bittorrent/:/downloads \
  --restart unless-stopped \
  lscr.io/linuxserver/qbittorrent:latest

docker run -d \
--name=baidunetdisk \
-p 5800:5800 \
-p 5900:5900 \
-v ~/baidunetdisk/config:/config \
-v /mnt/DataDisk1_6T/Download/baidunetdisk:/config/downloads \
-e VNC_PASSWORD=admin123 \
johngong/baidunetdisk:latest