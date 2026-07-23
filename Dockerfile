# Team-review preview image for the Migration Assistant docs.
#
# NOT a production artifact. Builds the static Jekyll site with
# JEKYLL_ENV=preview (which enables the Hypothesis annotation embed) and
# serves it with nginx. Root redirects to the Migration Assistant landing page.
#
# This file and deploy-preview/ live only on the preview branch and are never
# part of the upstream docs PR.

# ---- Stage 1: build the static site ----
FROM docker.io/library/ruby:3.3 AS build

WORKDIR /site
# Copy the whole repo before bundling: the Gemfile references a local gem
# (jekyll-spec-insert at ./spec-insert), so Gemfile/Gemfile.lock alone are
# not enough for `bundle install`.
COPY . .
RUN bundle install

# Build with the preview overlay: JEKYLL_ENV=preview enables the Hypothesis
# embed in _includes/head_custom.html; _config_preview.yml empties `url` so
# links are host-agnostic.
ENV JEKYLL_ENV=preview
RUN bundle exec jekyll build \
      --config _config.yml,deploy-preview/_config_preview.yml \
      --destination /build/latest

# ---- Stage 2: serve with nginx ----
FROM docker.io/library/nginx:1.27-alpine

COPY deploy-preview/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /build /usr/share/nginx/html

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
