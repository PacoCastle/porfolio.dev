# -----------------------------------------------------------------------------
# Dockerfile for building and serving an Astro (Node.js) portfolio application.
#
# Stage 1: Build
#   - Uses node:20-alpine for a lightweight Node.js environment.
#   - Sets the working directory to /app.
#   - Copies package.json and package-lock.json for dependency installation.
#   - Installs all dependencies (including devDependencies).
#   - Copies the rest of the application source code.
#   - Runs the build script to generate the production-ready output in /app/dist.
#
# Stage 2: Serve
#   - Uses a fresh node:20-alpine image for a clean runtime environment.
#   - Sets the working directory to /app.
#   - Copies only the package.json and package-lock.json from the builder stage.
#   - Installs only production dependencies (using --omit=dev).
#   - Copies the built output from /app/dist in the builder stage.
#   - Installs the 'serve' package globally to serve static files.
#   - Exposes port 3000.
#   - Sets the default command to serve the built site on port 3000.
# -----------------------------------------------------------------------------

# Stage 1: Build
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build

# Stage 2: Serve
FROM node:20-alpine

WORKDIR /app

COPY --from=builder /app/package*.json ./
RUN npm install --omit=dev

COPY --from=builder /app/dist ./dist

RUN npm install -g serve

EXPOSE 3000

CMD ["serve", "dist", "-l", "3000"]

