# Stage 1: Base image for all subsequent stages
# Using node:20-alpine for a smaller image size
FROM node:20-alpine AS base

# Install pnpm globally in the base image
RUN npm install -g pnpm

# Set the working directory inside the container for all stages
WORKDIR /app

# Stage 2: Dependencies for the Client (Vue/Vuetify)
FROM base AS client-deps
WORKDIR /app/client
# Copy only package.json and pnpm-lock.yaml to leverage Docker cache
COPY client/package.json client/pnpm-lock.yaml ./
# Install dependencies using pnpm
RUN pnpm install --frozen-lockfile

# Stage 3: Build the Client (Vue/Vuetify)
FROM client-deps AS client-build
WORKDIR /app/client
# Copy all client source code
COPY client ./
# Build the Vue application for production using pnpm. This typically outputs to a 'dist' folder.
RUN pnpm build

# Stage 4: Development Client
FROM client-deps AS client-dev
WORKDIR /app/client
# Copy all client source code
COPY client ./
# Expose the port your Vite dev server listens on
EXPOSE 5173
# Command to run the client in development mode using pnpm
CMD ["pnpm", "dev"]

# Stage 5: Production Client (Nginx to serve static files)
# Using a lightweight Nginx image for serving static content
FROM nginx:alpine AS client-prod
# Copy the built Vue app from the client-build stage into Nginx's default public directory
# 'dist' is the common output folder for Vite builds.
COPY --from=client-build /app/client/dist /usr/share/nginx/html
# Expose the default Nginx port
EXPOSE 80
# Nginx runs as the default CMD
CMD ["nginx", "-g", "daemon off;"]
