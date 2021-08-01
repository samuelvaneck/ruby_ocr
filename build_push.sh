docker build -t ghcr.io/samuelvaneck/ruby_ocr:latest .
echo $CR_PAT | docker login ghcr.io --username samuelvaneck --password-stdin
docker tag ghcr.io/samuelvaneck/ruby_ocr:latest
docker push ghcr.io/samuelvaneck/ruby_ocr:latest
