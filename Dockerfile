FROM surnet/alpine-wkhtmltopdf:3.9-0.12.5-small AS wkhtmltopdf
FROM ruby:2.7.5-alpine

LABEL maintainer "Daniel Roestorf <daniel.roestorf@maisonette.com>"

WORKDIR /app

COPY --from=wkhtmltopdf /bin/wkhtmltopdf /usr/local/bin/wkhtmltopdf

RUN chmod 0755 /usr/local/bin/wkhtmltopdf

RUN apk add --update \
    bash \
    build-base \
    curl \
    git \
    imagemagick \
    imagemagick-dev \
    nodejs \
    postgresql-dev \
    postgresql \
    python3 \
    tzdata \
    libstdc++ \
    libx11 \
    libxrender \
    libxext \
    libssl1.1 \
    ca-certificates \
    fontconfig \
    freetype \
    ttf-dejavu \
    ttf-droid \
    ttf-freefont \
    ttf-liberation \
    zip && \
    apk add --no-cache --virtual .build-deps \
    msttcorefonts-installer && \
    update-ms-fonts && \
    fc-cache -f

RUN curl -O https://bootstrap.pypa.io/get-pip.py && \
    python3 get-pip.py pip==18.1 --user && rm get-pip.py && \
    /root/.local/bin/pip3 install awscli --upgrade && \
    aws --version

RUN gem install bundler --version 2.2.11
COPY Gemfile .
COPY Gemfile.lock .
COPY vendor/cache vendor/cache
RUN bundle install --local

ARG AWS_S3_REGION
ARG AWS_S3_BUCKET
ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY

ENV AFTERPAY_TEST_MODE=false \
    AFTERPAY_MERCHANT_ID=false \
    AFTERPAY_SECRET_KEY=false \
    AFTERPAY_PAYMENT_GATEWAY_ID=${AFTERPAY_PAYMENT_GATEWAY_ID} \
    AFTERPAY_GATEWAY_REF_NUMBER=${AFTERPAY_GATEWAY_REF_NUMBER} \
    AVATAX_COMPANY_CODE=false \
    AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
    AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
    AWS_REGION=${AWS_S3_REGION} \
    AWS_S3_BUCKET=${AWS_S3_BUCKET} \
    AWS_S3_PRIVATE_BUCKET=false \
    AWS_S3_SYNDICATION_BUCKET=false \
    BRAINTREE_ENV=false \
    BRAINTREE_MERCHANT_ID=false \
    BRAINTREE_PUBLIC_KEY=false \
    BRAINTREE_PRIVATE_KEY=false \
    ASSETS_CDN=false \
    EASYPOST_API_KEY=false \
    JIFITI_ADMIN_USER=false \
    JIFITI_ORDER_EMAIL=false \
    JIFITI_MAIS_ORDER_EMAIL=false \
    KUSTOMER_API_KEY=false \
    KUSTOMER_WEBHOOKS_ORDER=false \
    KUSTOMER_WEBHOOKS_CUSTOMER=false \
    MERCH_EMAIL=false \
    MIRAKL_API_ENDPOINT=false \
    MIRAKL_FRONT_KEY=false \
    MIRAKL_OPERATOR_KEY=false \
    MIRAKL_URL=false \
    MOENGAGE_API_SECRET=false \
    MOENGAGE_APP_ID=false \
    NARVAR_API_URL=false \
    NARVAR_API_USERNAME=false \
    NARVAR_API_PASSWORD=false \
    NARVAR_RETURN_URL=false \
    OPS_SUPPORT_EMAIL=false \
    PACCURATE_API_KEY=false \
    REDIS_URL_SIDEKIQ=redis://false \
    REDIS_URL_SERVICE=redis://false \
    SALSIFY_API_ENDPOINT=false \
    SALSIFY_AUTH_TOKEN=false \
    SALSIFY_FTP_HOSTNAME=false \
    SALSIFY_FTP_USERNAME=false \
    SALSIFY_FTP_PASSWORD=false \
    SALSIFY_ORGANIZATION_ID=false \
    SALSIFY_REPORTS_EMAIL=false \
    SUPPORT_EMAIL=false \
    VENDOR_SUPPORT_EMAIL=false \
    OMS_CLIENT_ID=false \
    OMS_CLIENT_SECRET=false \
    OMS_PASSWORD=false \
    OMS_SECURITY_TOKEN=false \
    OMS_USERNAME=false \
    OMS_PRODUCTION_MODE=false \
    OMS_CARD_PAYMENT_GATEWAY_ID=false \
    OMS_DIGITAL_WALLET_PAYMENT_GATEWAY_ID=false \
    OMS_LINE_ITEM_PRICEBOOK_ENTRY_ID=false \
    OMS_SHIPMENT_PRICEBOOK_ENTRY_ID=false \
    OMS_PAYMENT_GATEWAY_ID=false \
    OMS_PRICEBOOK2_ID=false \
    OMS_PRODUCT2_ID=false \
    ZYTE_ENVIRONMENT=false \
    ZYTE_AWS_REGION=false \
    ZYTE_AWS_BUCKET=false

COPY . .

RUN bundle exec rake assets:precompile

RUN aws s3 cp /app/public/ s3://${AWS_S3_BUCKET}/ --recursive

ENV AWS_ACCESS_KEY_ID=false \
    AWS_SECRET_ACCESS_KEY=false \
    AWS_S3_BUCKET=false \
    AWS_REGION=false

EXPOSE 3000 8126/tcp

CMD ["/bin/bash", "init.sh"]
