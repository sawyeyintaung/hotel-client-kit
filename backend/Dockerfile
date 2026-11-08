# Express production image
FROM node:22-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
# Runs "npm run build" only if you have one (e.g. TypeScript)
RUN npm run build --if-present
RUN npm prune --omit=dev

FROM node:22-alpine
WORKDIR /app
ENV NODE_ENV=production \
    PORT=4000
COPY --from=build /app ./
USER node
EXPOSE 4000
# Uses the "start" script in package.json
CMD ["npm", "start"]
