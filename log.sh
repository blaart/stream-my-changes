while true
do
  docker-compose logs -f -t $1
  echo "$1 is unavailable - sleeping"
  sleep 5
done
