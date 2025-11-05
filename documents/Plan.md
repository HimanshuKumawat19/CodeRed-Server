

> This plan is structured as a dynamic checklist. Use Obsidian plugins like `Tasks` and `Dataview` to track progress automatically.

## 📈 Overall Project Progress

```dataviewjs
// --- Overall Progress Calculation --- 
const file = dv.current().file; const allTasks = file.tasks.where(t => !t.fullyCompleted); const totalCompleted = allTasks.where(t => t.completed).length; const totalTasks = allTasks.length; const overallPercentage = totalTasks ? Math.round((totalCompleted / totalTasks) * 100) : 0; dv.header(3, `Overall Project Status: ${overallPercentage}%`); dv.el("progress", "", { attr: { value: totalCompleted, max: totalTasks } }); dv.paragraph(`*${totalCompleted} of ${totalTasks} total tasks completed.*`); 
// --- Phase-wise Progress Dashboard --- 
const createCircle = (percentage, phaseName, completed, total) => { const size = 140; const strokeWidth = 12; const radius = (size - strokeWidth) / 2; const circumference = 2 * Math.PI * radius; const offset = circumference - (percentage / 100) * circumference; const svg = ` <div style="position: relative; width: ${size}px; height: ${size}px;"> <svg width="${size}" height="${size}" viewbox="0 0 ${size} ${size}" style="transform: rotate(-90deg);"> <circle stroke="#dde1e7" stroke-width="${strokeWidth}" fill="transparent" r="${radius}" cx="${size/2}" cy="${size/2}"/> <circle stroke="#4a90e2" stroke-width="${strokeWidth}" stroke-linecap="round" fill="transparent" r="${radius}" cx="${size/2}" cy="${size/2}" style="stroke-dasharray: ${circumference}; stroke-dashoffset: ${offset}; transition: stroke-dashoffset 0.5s ease-in-out;"/> </svg> <div style="position: absolute; top: 0; left: 0; width: 100%; height: 100%; display: flex; flex-direction: column; align-items: center; justify-content: center; font-family: sans-serif;"> <span style="font-size: 28px; font-weight: bold; color: #333;">${percentage}%</span> <span style="font-size: 12px; color: #777;">${completed}/${total}</span> </div> </div> <div style="text-align: center; font-weight: bold; margin-top: 8px; font-family: sans-serif; color: #333;">${phaseName}</div> `; const container = dv.el("div", "", { attr: { style: "display: flex; flex-direction: column; align-items: center; margin: 15px;" } }); container.innerHTML = svg; return container; }; const phases = file.tasks.groupBy(t => { const heading = t.section.subpath; if (heading && heading.startsWith("Phase")) return heading; return null; }).filter(p => p.key !== null); const dashboard = dv.el("div", "", { attr: { style: "display: flex; flex-wrap: wrap; justify-content: center; align-items: flex-start; gap: 20px; margin-top: 20px;" } }); phases.forEach(phase => { const phaseTitle = phase.key.split(":")[0]; 
// Gets "Phase 1" 
const tasks = phase.rows; const completed = tasks.where(t => t.completed).length; const total = tasks.length; const percentage = total ? Math.round((completed / total) * 100) : 0; dashboard.appendChild(createCircle(percentage, phaseTitle, completed, total)); }); dv.el("div", dashboard);
```


## Phase 1: Foundation & Core Infrastructure

> **🎯 Objective:** Establish a stable, scalable foundation for the application, including the database schema, core application setup, and a secure authentication system.

### ✅ Step 1: Environment & Database Setup

- [x] **Task: Set up Local Development Environment** ✅ 2025-10-11
    
    - [x] Install PostgreSQL locally. ✅ 2025-10-09
        
    - [x] Install DBeaver or a similar DB management tool. ✅ 2025-10-09
        
    - [x] Create the `codeforge_dev` database. ✅ 2025-10-10
        
- [ ] **Task: Design & Implement Initial Database Schema**
    
    - [ ] Design the `users` table schema with all necessary constraints.
        
    - [ ] Design the `problems` table schema (including columns for title, description, difficulty, topic).
        
    - [ ] Design the `test_cases` table linked to problems.
        
    - [ ] Design the `matches` table to store match metadata.
        
    - [ ] Design the `match_participants` table to link users to matches.
        
    - [ ] Write and execute the `CREATE TABLE` SQL scripts for all initial tables.
        

### ✅ Step 2: Backend Foundation & Configuration

- [ ] **Task: Initialize FastAPI Application**
    
    - [ ] Set up the project structure from the architecture plan.
        
    - [ ] Initialize a virtual environment (`venv` or `poetry`).
        
    - [ ] Install FastAPI, Uvicorn, and SQLAlchemy.
        
    - [ ] Create `app/main.py` with a basic root endpoint (`@app.get("/")`).
        
    - [ ] Run the server locally to confirm it works.
        
- [ ] **Task: Configure Database Connection**
    
    - [ ] Create `app/config.py` to manage environment variables using Pydantic Settings.
        
    - [ ] Create `.env` file and add the database connection URL.
        
    - [ ] Create `app/database.py` to set up the SQLAlchemy engine and session manager.
        
- [ ] **Task: Implement SQLAlchemy Models**
    
    - [ ] Create `models/user.py` corresponding to the `users` table.
        
    - [ ] Create `models/problem.py` for problems and test cases.
        
    - [ ] Create `models/match.py` for matches and participants.
        
    - [ ] Ensure all models are imported correctly in a base file.
        

###  ✅ Step 3: Secure Authentication System

- [ ] **Task: Implement Core Security**
    
    - [ ] Implement password hashing functions using `passlib` with bcrypt in `core/security.py`.
        
    - [ ] Implement JWT access and refresh token creation logic.
        
    - [ ] Implement token decoding and validation logic.
        
- [ ] **Task: Create Pydantic Schemas for Auth**
    
    - [ ] Create `schemas/user.py` for user creation and response.
        
    - [ ] Create `schemas/token.py` for token data and response.
        
- [ ] **Task: Build Authentication Endpoints**
    
    - [ ] Implement the `POST /api/v1/auth/register` endpoint.
        
    - [ ] Implement the `POST /api/v1/auth/login` endpoint using an OAuth2 password flow.
        
    - [ ] Implement the `POST /api/v1/auth/refresh` endpoint to get a new access token.
        
- [ ] **Task: Add Authentication Dependencies**
    
    - [ ] Create a dependency in `dependencies.py` to get the current authenticated user from a token.
        
    - [ ] Protect a test endpoint to ensure the dependency works.
        

## Phase 2: Core Feature Implementation

> **🎯 Objective:** Build out the primary features of the platform, including user profiles, problem management, and the real-time communication backbone.

###  ✅ Step 4: User & Friends System

- [ ] **Task: Develop User Profile Endpoints**
    
    - [ ] Create the `GET /api/v1/users/me` endpoint to fetch the current user's private profile.
        
    - [ ] Create the `GET /api/v1/users/{user_id}` endpoint for public profiles.
        
    - [ ] Implement CRUD functions in `crud/user.py` to support these endpoints.
        
- [ ] **Task: Implement Friends System**
    
    - [ ] Design the `friends` table schema (e.g., `user_id_1`, `user_id_2`, `status`).
        
    - [ ] Implement the `POST /api/v1/friends/request` endpoint.
        
    - [ ] Implement an endpoint to accept/decline friend requests.
        
    - [ ] Implement the `GET /api/v1/friends` endpoint to list a user's friends.
        

###  ✅ Step 5: Problem Management System

- [ ] **Task: Build Problem CRUD API**
    
    - [ ] Implement `crud/problem.py` for database operations.
        
    - [ ] Create the `GET /api/v1/problems` endpoint with filtering (by difficulty, topic).
        
    - [ ] Create the `GET /api/v1/problems/{problem_id}` endpoint.
        
    - [ ] Create a protected `POST /api/v1/problems` endpoint for admins to add new problems.
        
- [ ] **Task: Populate Database**
    
    - [ ] Write a script to populate the database with at least 20 sample DSA problems.
        
    - [ ] Ensure each problem has multiple, well-defined test cases.
        

###  ✅ Step 6: Real-Time Infrastructure (WebSockets)

- [ ] **Task: Set Up WebSocket Manager**
    
    - [ ] Create a `ConnectionManager` class in `websockets/manager.py` to handle active connections.
        
    - [ ] Implement methods for `connect`, `disconnect`, and broadcasting messages.
        
- [ ] **Task: Implement Matchmaking WebSocket**
    
    - [ ] Create the `/ws/matchmaking` endpoint.
        
    - [ ] Implement logic for users to join and leave the matchmaking queue via WebSocket messages.
        

## Phase 3: The Core Game Loop

> **🎯 Objective:** Implement the main "gameplay" of CodeForge, from finding an opponent to the live match experience and code execution.

###  ✅ Step 7: The Matchmaking Engine

- [ ] **Task: Implement Matching Algorithm**
    
    - [ ] In `core/matchmaking.py`, create a function that periodically scans the queue.
        
    - [ ] Implement logic to find pairs of users with similar MMR within a certain range.
        
    - [ ] As an innovation, make the MMR range expand the longer a user waits.
        
- [ ] **Task: Implement Match Creation Flow**
    
    - [ ] When a match is found, create a new record in the `matches` table.
        
    - [ ] Randomly select a problem appropriate for the players' average MMR.
        
    - [ ] Notify both users via WebSocket with the `match_id` and redirect them.
        

###  ✅ Step 8: The Live Match Experience

- [ ] **Task: Implement Live Match WebSocket**
    
    - [ ] Create the `/ws/match/{match_id}` endpoint.
        
    - [ ] Users joining this endpoint will be added to a "match room".
        
- [ ] **Task: Handle Real-time Events**
    
    - [ ] Implement logic to broadcast events like "opponent_joined", "match_started".
        
    - [ ] Implement a server-side timer and broadcast time updates.
        
    - [ ] Handle incoming code submission events from users.
        
    - [ ] Broadcast a "typing" status to the opponent for a more dynamic feel.
        

###  ✅ Step 9: Secure Code Execution Service

- [ ] **Task: Design the Service**
    
    - [ ] Decide on an execution strategy: external API (Judge0) or self-hosted Docker containers.
        
    - [ ] Design the service in `services/code_execution_service.py` to be pluggable.
        
- [ ] **Task: Implement Execution Logic**
    
    - [ ] Implement a function that takes code, language, and test cases as input.
        
    - [ ] It should return `success/fail`, output, and execution time.
        
    - [ ] Implement robust error handling and timeouts to prevent abuse.
        

## Phase 4: Game Resolution & Analytics

> **🎯 Objective:** Finalize the gameplay loop by determining winners, updating stats, and providing valuable analytics like leaderboards and match history.

### ✅ Step 10: Match Resolution & Ranking

- [ ] **Task: Determine Winner**
    
    - [ ] When a user's submission passes all test cases, declare them the winner.
        
    - [ ] Update the `matches` table with the winner and final scores.
        
- [ ] **Task: Update User Stats & MMR**
    
    - [ ] In `core/ranking.py`, implement an Elo-based MMR calculation.
        
    - [ ] After a match, update the `mmr`, `wins`/`losses`, and `matches_played` for both users.
        
    - [ ] Update the user's `rank` (e.g., Bronze -> Silver) if their MMR crosses a threshold.
        

###  ✅ Step 11: Leaderboard & History

- [ ] **Task: Build Analytics Endpoints**
    
    - [ ] Create the `GET /api/v1/leaderboard` endpoint, which returns the top users sorted by MMR.
        
    - [ ] Create the `GET /api/v1/users/me/matches` endpoint for a user's personal match history.
        
    - [ ] Implement caching (e.g., with Redis) for the leaderboard to reduce database load.
        

## Phase 5 & 6: Integration & Deployment

### ✅ Step 12 & 13: Frontend Integration & Testing

- [ ] **Task: Coordinate & Test with Frontend**
    
    - [ ] Share API documentation (`/docs`) and WebSocket protocols.
        
    - [ ] Perform end-to-end testing of the full registration-to-match-completion flow.
        
    - [ ] Use tools to simulate multiple concurrent users and test for race conditions.
        

### ✅ Step 14: Production Readiness

- [ ] **Task: Dockerize the Application**
    
    - [ ] Write a `Dockerfile` for the FastAPI application.
        
    - [ ] Use a production-grade server like Gunicorn with Uvicorn workers.
        
- [ ] **Task: Prepare for Deployment**
    
    - [ ] Set up production configuration and secrets management.
        
    - [ ] Implement structured logging for better monitoring.
        
    - [ ] Create deployment scripts or a `render.yaml` file for PaaS deployment.