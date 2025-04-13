set -xe

docker build --platform linux/amd64 -t ghcr.io/samuelvaneck/ruby_ocr:latest .
echo $CR_PAT | docker login ghcr.io --username samuelvaneck --password-stdin
docker push ghcr.io/samuelvaneck/ruby_ocr:latest
