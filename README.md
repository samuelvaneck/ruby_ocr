# A Simple OCR using Tesseract and Sinatra
This app uses the Tesseract OCR for converting images into plain text

## Run with Docker
```
  # build docker container:
  docker build --tag ruby_ocr .

  # run docker container:
  docker run -p 80:9292 ruby_ocr

  # push not image to repository
  ./build_push.sh

```

## Run in development
```
  bundle exec rerun -b -- rackup
```

## Open your browser
```
  http://localhost:9292
```
