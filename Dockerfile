FROM --platform=linux/amd64 ruby:3.2.2-alpine3.18
RUN apk update && apk add tesseract-ocr build-base poppler-utils curl
RUN wget https://github.com/google/fonts/archive/main.tar.gz -O gf.tar.gz && \
  tar -xf gf.tar.gz && \
  mkdir -p /usr/share/fonts/truetype/google-fonts && \
  find $PWD/fonts-main/ -name "*.ttf" -exec install -m644 {} /usr/share/fonts/truetype/google-fonts/ \; || return 1 && \
  rm -f gf.tar.gz && \
  rm -rf $PWD/fonts-main && \
  rm -rf /var/cache/* && \
  fc-cache -f

RUN bundle config set deployment 'true'

WORKDIR /app
COPY . /app
RUN bundle install --without development

EXPOSE 4567

CMD ["bundle", "exec", "rackup", "--host", "0.0.0.0", "-p", "9292"]
