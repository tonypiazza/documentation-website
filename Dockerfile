# Review preview image for the Migration Assistant docs.
#
# NOT a production artifact. Builds the static Jekyll site and serves it with
# nginx. Root redirects to the Migration Assistant landing page.
#
# No annotation tooling: JEKYLL_ENV is deliberately left unset so the build
# matches what a reader would see on the published site. The Hypothesis embed
# used by the earlier internal preview was guarded by
# `jekyll.environment == "preview"`, so leaving the variable unset is what
# keeps it out. Do not reintroduce JEKYLL_ENV=preview here.
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

# Build with the preview overlay: _config_preview.yml empties `url` so links
# are host-agnostic and resolve at whatever hostname Aiven assigns.
RUN bundle exec jekyll build \
      --config _config.yml,deploy-preview/_config_preview.yml \
      --destination /build/latest

# ---- Stage 2: serve with nginx ----
FROM docker.io/library/nginx:1.27-alpine

COPY deploy-preview/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /build /usr/share/nginx/html
# Root index.html redirects to the MA docs client-side (see nginx.conf comment).
COPY deploy-preview/root-index.html /usr/share/nginx/html/index.html

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
