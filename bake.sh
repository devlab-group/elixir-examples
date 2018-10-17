task:run() {
  docker run --rm \
    -v $CWD:/app \
    -v $CWD/.mix:/root/.mix \
    -w /app \
    -p 4000:4000 \
    -ti elixir $@
}

task:elixir() {
  task:run elixir $@
}

task:mix() {
  task:run mix $@
}

task:new() {
  task:mix new $@ || exit 1
  echo "To change permissions run:"
  echo
  echo "sudo chown $USER:$USER -R $1"
}
