rsync -v -a --exclude=.git --exclude=node_modules --exclude=server.log --exclude=data --exclude=.npm . colin@lab.colinscape.com:~/site
ssh colin@lab.colinscape.com "cd site && npm install"
ssh colin@lab.colinscape.com "sudo killall node"
ssh colin@lab.colinscape.com "cd site && ./start.sh"