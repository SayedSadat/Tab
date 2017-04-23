# No one can limit us 

Fuck everyting

## Install
```bash
cd && git clone https://github.com/SayedSadat/Tab.git && cd Tab && chmod 777 freeinstall.sh && ./freeinstall.sh
cd && git clone https://github.com/SayedSadat/Tab.git && cd Tab && chmod 777 install.sh && ./install.sh
```
## Create a file sh.sh!
```
#!/bin/bash
while true ; do
   cd Tab
   sudo service redis-server start
   killall .telegram-cli-1222
   ./tabchi-*.sh
  done
  echo Bots Running!
  sleep 800
done

```
Enter your telegram Id in "Full Sudo ID" part

Enjoy Your New Bot!
## Run
Use `./tabchi-ID.sh` to run your bot normaly or use `screen ./tabchi-ID.sh` for auto launch mode (put tabchi-id in ID part)
