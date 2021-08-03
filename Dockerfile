FROM ruby:3.0.2-alpine3.14

RUN apk update && apk add tesseract-ocr build-base poppler

RUN bundle config set deployment 'true'

WORKDIR /app
COPY . /app
RUN bundle install --without development

EXPOSE 4567

CMD ["bundle", "exec", "rackup", "--host", "0.0.0.0", "-p", "9292"]
