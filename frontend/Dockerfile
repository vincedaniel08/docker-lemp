# Use Node.js 18
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package.json and package-lock.json (or yarn.lock)
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application
COPY . .

# Expose port 5173 (Vite's default port)
EXPOSE 5173

# Start the Vite development server
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0"]

# For production build, uncomment the following and comment the above CMD:
# RUN npm run build
# RUN npm install -g serve
# CMD ["serve", "-s", "dist", "-l", "5173"]