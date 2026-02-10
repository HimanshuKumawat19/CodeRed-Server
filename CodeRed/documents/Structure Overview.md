# 🏗️ Project Structure Overview

## 📁 Root Level Structure

```
server/
├── 📂 app/                 # FastAPI application core
├── 📂 api/                # API routes and endpoints  
├── 📂 core/               # Business logic and core services
├── 📂 models/             # Database models (SQLAlchemy)
├── 📂 schemas/            # Pantic schemas for validation
├── 📂 crud/               # Database operations layer
├── 📂 services/           # Business logic services
├── 📂 utils/              # Utilities and helpers
└── 📂 tests/              # Test suite
```

## 📂 Detailed Folder Breakdown

### 🎯 app/ - Application Core & Configuration

**Purpose:** Central application setup, configuration, and dependency management

**Files:**

- `main.py` - FastAPI app instance, middleware, route inclusion
    
- `config.py` - Environment variables and configuration management
    
- `database.py` - Database connection, session management, engine setup
    
- `dependencies.py` - Shared dependencies (auth, DB sessions, etc.)
    

**Why this structure?**

- Single source of truth for app configuration
    
- Clean separation of app setup from business logic
    
- Easy dependency injection across the application
    

**Future Changes:**

- Add configuration for different environments (dev/staging/prod)
    
- Implement more middleware (rate limiting, logging, CORS)
    
- Add database migration management (Alembic setup)
    

### 🌐 api/ - API Routes & Endpoints

**Purpose:** Handle HTTP requests, WebSocket connections, and route definitions

**Structure:**

```
api/
├── v1/                    # API versioning
│   ├── endpoints/         # REST API endpoints
│   └── websockets/        # WebSocket handlers
```

**Files:**

- `endpoints/auth.py` - User registration, login, token management
    
- `endpoints/users.py` - User profiles, statistics, match history
    
- `endpoints/matches.py` - Match operations, history, results
    
- `endpoints/problems.py` - Problem CRUD operations
    
- `endpoints/leaderboard.py` - Ranking and leaderboard data
    
- `endpoints/friends.py` - Friend system operations
    
- `websockets/matchmaking.py` - Real-time matchmaking queue
    
- `websockets/live_matches.py` - Live match communication
    

**Why this structure?**

- Clear separation between REST and WebSocket handlers
    
- Versioning support for future API changes
    
- Organized by domain/resource
    

**Future Changes:**

- Add v2 API when breaking changes are needed
    
- Implement API documentation enhancements
    
- Add rate limiting per endpoint
    
- Implement request/response logging
    

### ⚡ core/ - Business Logic & Core Services

**Purpose:** Contains the core business logic independent of API layer

**Files:**

- `security.py` - JWT token handling, password hashing, authentication logic
    
- `matchmaking.py` - Matchmaking algorithm, queue management
    
- `ranking.py` - MMR calculations, rank determination, Elo-like system
    
- `code_execution.py` - Integration with code execution services
    

**Why this structure?**

- Business logic separated from API concerns
    
- Reusable across different endpoints
    
- Easy to test independently
    
- Can be used by background tasks or other services
    

**Future Changes:**

- Implement more sophisticated matchmaking algorithms
    
- Add multiple ranking systems (different game modes)
    
- Integrate with external code execution services (Judge0, Sphere Engine)
    
- Add caching layer for frequently accessed data
    

### 🗄️ models/ - Database Models

**Purpose:** SQLAlchemy ORM models defining database schema

**Files:**

- `user.py` - User accounts, profiles, statistics
    
- `problem.py` - Coding problems, test cases, constraints
    
- `match.py` - Match records, submissions, results
    
- `friend.py` - Friend relationships, requests
    

**Why this structure?**

- Clear database schema definition
    
- Easy relationships between entities
    
- Type hints and validation
    
- Single responsibility per model
    

**Future Changes:**

- Add more models (tournaments, groups, notifications)
    
- Implement database indexing strategies
    
- Add composite models for complex queries
    
- Implement soft deletes where needed
    

### 📋 schemas/ - Pydantic Schemas

**Purpose:** Request/response validation, serialization, API contracts

**Files:**

- `user.py` - User creation, update, response schemas
    
- `problem.py` - Problem data, test case schemas
    
- `match.py` - Match creation, submission, result schemas
    
- `friend.py` - Friend request, relationship schemas
    

**Why this structure?**

- Separation of validation from database models
    
- Different schemas for different operations (create/update/response)
    
- API contract enforcement
    
- Input sanitization and validation
    

**Future Changes:**

- Add more specific validation rules
    
- Implement custom validators for complex logic
    
- Add schema versioning for API evolution
    

### 🛠️ crud/ - Database Operations Layer

**Purpose:** Database operations following Repository pattern

**Files:**

- `base.py` - Base CRUD operations (get, create, update, delete)
    
- `user.py` - User-specific database operations
    
- `problem.py` - Problem-related queries
    
- `match.py` - Match operations and analytics
    
- `friend.py` - Friend system database logic
    

**Why this structure?**

- Separation of database operations from business logic
    
- Reusable database queries
    
- Easy to mock for testing
    
- Centralized query optimization
    

**Future Changes:**

- Implement query optimization for complex operations
    
- Add database transaction management
    
- Implement read replicas for scaling
    
- Add database connection pooling optimizations
    

### 🔧 services/ - Business Logic Services

**Purpose:** Orchestrate business logic using multiple CRUD operations

**Files:**

- `auth_service.py` - Authentication and authorization logic
    
- `match_service.py` - Match flow, result processing, MMR updates
    
- `problem_service.py` - Problem management, random selection
    
- `code_execution_service.py` - Code execution and validation
    

**Why this structure?**

- Business logic coordination
    
- Transaction management across multiple operations
    
- Service layer pattern for complex workflows
    
- Easy to unit test business scenarios
    

**Future Changes:**

- Add background task processing (Celery)
    
- Implement event-driven architecture
    
- Add service monitoring and metrics
    
- Implement circuit breakers for external services
    

### 🧰 utils/ - Utilities & Helpers

**Purpose:** Reusable utility functions and constants

**Files:**

- `helpers.py` - Generic helper functions (datetime, formatting, etc.)
    
- `constants.py` - Application constants (ranks, difficulties, etc.)
    

**Why this structure?**

- Avoid code duplication
    
- Centralized configuration of constants
    
- Reusable across entire application
    
- Easy maintenance and updates
    

**Future Changes:**

- Add more utility functions as needed
    
- Implement custom exceptions
    
- Add logging configuration and helpers
    
- Implement configuration validators
    

### 🧪 tests/ - Test Suite

**Purpose:** Comprehensive testing across all layers

**Structure:**

```
tests/
├── test_api/           # API endpoint tests
├── test_services/      # Service layer tests  
├── test_core/          # Core logic tests
└── conftest.py         # Test fixtures and configuration
```

**Why this structure?**

- Organized testing by application layer
    
- Easy to run specific test suites
    
- Clear separation of unit vs integration tests
    
- Reusable test fixtures
    

**Future Changes:**

- Add integration test suite
    
- Implement performance testing
    
- Add API contract testing
    
- Implement test data factories
    

## 🎯 Key Architectural Decisions

**1. Separation of Concerns**

- API layer only handles HTTP/WebSocket communication
    
- Business logic in services and core modules
    
- Database operations isolated in CRUD layer
    
- Validation separated in schemas
    

**2. Testability**

- Each layer can be tested independently
    
- Easy mocking of dependencies
    
- Clear boundaries between components
    

**3. Scalability**

- Stateless design for horizontal scaling
    
- Database-agnostic business logic
    
- Service layer ready for microservices split
    

**4. Maintainability**

- Clear folder structure for easy navigation
    
- Consistent patterns across the codebase
    
- Documentation-ready with type hints
    

## 🔮 Future Evolution Path

**Phase 1: Current Structure**

- Monolithic FastAPI application
    
- Single PostgreSQL database
    
- Direct service communication
    

**Phase 2: Microservices Ready**

- Extract matchmaking service
    
- Separate code execution service
    
- Implement message queue (Redis/RabbitMQ)
    

**Phase 3: Full Microservices**

- User service
    
- Match service
    
- Problem service
    
- Ranking service
    
- API Gateway