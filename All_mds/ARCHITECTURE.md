# Elevate Learning - Microservices Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         INTERNET / USERS                             │
└───────────────────────────────┬─────────────────────────────────────┘
                                │
                                │ HTTP (Port 80)
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                       NGINX REVERSE PROXY                            │
│                     (Load Balancer & Cache)                          │
│  - Static file serving                                               │
│  - Request routing                                                   │
│  - Load balancing across Django replicas                            │
└───────────────────────────────┬─────────────────────────────────────┘
                                │
                                │ HTTP (Port 8000)
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│              DJANGO WEB APPLICATION (2 Replicas)                     │
│                                                                       │
│  ┌──────────────────┐  ┌──────────────────┐                        │
│  │  Django Web #1   │  │  Django Web #2   │                        │
│  │  - User Auth     │  │  - User Auth     │                        │
│  │  - Course CRUD   │  │  - Course CRUD   │                        │
│  │  - Progress      │  │  - Progress      │                        │
│  │  - Social        │  │  - Social        │                        │
│  └──────────────────┘  └──────────────────┘                        │
│                                                                       │
└────────────┬─────────────────────────────┬────────────────────────┘
             │                             │
             │ MySQL (3306)                │ Redis (6379)
             ▼                             ▼
┌─────────────────────────┐   ┌─────────────────────────┐
│   MYSQL DATABASE        │   │   REDIS CACHE           │
│   - User data           │   │   - Session cache       │
│   - Courses             │   │   - Query cache         │
│   - Progress tracking   │   │   - Performance boost   │
│   - Comments            │   │                         │
│   - Persistent storage  │   │                         │
│   (10GB Volume)         │   │                         │
└─────────────────────────┘   └─────────────────────────┘
```

## Container Communication

```
┌──────────────────────────────────────────────────────────────┐
│                 Docker Network (overlay/bridge)              │
│                                                              │
│  ┌─────────┐    ┌──────────┐    ┌──────┐    ┌────────┐   │
│  │  Nginx  │───▶│ Django 1 │───▶│ MySQL│    │ Redis  │   │
│  │  :80    │    │  :8000   │    │ :3306│    │ :6379  │   │
│  └─────────┘    └──────────┘    └──────┘    └────────┘   │
│       │         ┌──────────┐         │            │       │
│       └────────▶│ Django 2 │─────────┘            │       │
│                 │  :8000   │                      │       │
│                 └──────────┘                      │       │
│                      │                            │       │
│                      └────────────────────────────┘       │
│                                                            │
└──────────────────────────────────────────────────────────┘
```

## Deployment Options Comparison

### Option 1: Docker Compose
```
┌─────────────────────────────┐
│      Docker Compose         │
│  ┌─────────────────────┐   │
│  │  Single Host        │   │
│  │  Easy to setup      │   │
│  │  Good for dev/test  │   │
│  └─────────────────────┘   │
└─────────────────────────────┘

Best for: Development, Testing
Pros: Simple, fast setup
Cons: Single host limitation
```

### Option 2: Docker Swarm
```
┌─────────────────────────────┐
│      Docker Swarm           │
│  ┌─────────────────────┐   │
│  │  Multiple Hosts     │   │
│  │  Auto scaling       │   │
│  │  Load balancing     │   │
│  │  High availability  │   │
│  └─────────────────────┘   │
└─────────────────────────────┘

Best for: Production (small-medium)
Pros: Built-in, easy orchestration
Cons: Less features than K8s
```

### Option 3: Kubernetes
```
┌─────────────────────────────┐
│      Kubernetes (K8s)       │
│  ┌─────────────────────┐   │
│  │  Enterprise-grade   │   │
│  │  Auto healing       │   │
│  │  Rolling updates    │   │
│  │  Advanced features  │   │
│  └─────────────────────┘   │
└─────────────────────────────┘

Best for: Production (large scale)
Pros: Industry standard, powerful
Cons: More complex setup
```

## Data Flow

### User Registration/Login Flow
```
User ──▶ Nginx ──▶ Django ──▶ MySQL
                     │           │
                     └───────────┘
                   Save user data
```

### Course Creation Flow (Educator)
```
Educator ──▶ Nginx ──▶ Django ──▶ MySQL
                         │           │
                         └───────────┘
                      Create course record
```

### Course Learning Flow (Learner)
```
Learner ──▶ Nginx ──▶ Django ──▶ MySQL (Get course)
                        │           │
                        │           └─────▶ Course data
                        │
                        └──────────▶ Redis (Cache)
                                      │
                                      └─────▶ Faster access
```

### Progress Tracking Flow
```
Learner completes page ──▶ Django ──▶ MySQL
                             │           │
                             │      Update progress
                             │           │
                             └───────────┘
                      Calculate percentage
                             │
                             ▼
                      Show certificate
                    (if 100% complete)
```

## Scalability Model

```
           Low Traffic                 High Traffic
                │                           │
                ▼                           ▼
    ┌─────────────────────┐    ┌─────────────────────┐
    │  Django: 2 replicas │    │  Django: 5 replicas │
    │  MySQL: 1 instance  │    │  MySQL: 1 instance  │
    │  Nginx: 1 instance  │    │  Nginx: 2 instances │
    │  Redis: 1 instance  │    │  Redis: 2 instances │
    └─────────────────────┘    └─────────────────────┘
            ↓                           ↓
    Handles 50-100 users      Handles 500+ users
```

## High Availability Setup

```
┌──────────────────────────────────────────────────────┐
│                  Load Balancer (GCP)                 │
└────────────────────┬──────────────────┬──────────────┘
                     │                  │
         ┌───────────▼────────┐    ┌────▼──────────────┐
         │   Node 1 (GCP VM)  │    │  Node 2 (GCP VM)  │
         │  ┌──────────────┐  │    │ ┌──────────────┐  │
         │  │ Django (2x)  │  │    │ │ Django (2x)  │  │
         │  │ Nginx        │  │    │ │ Nginx        │  │
         │  └──────────────┘  │    │ └──────────────┘  │
         └────────────────────┘    └───────────────────┘
                     │                  │
                     └──────────┬───────┘
                                │
                      ┌─────────▼────────┐
                      │  MySQL Cluster   │
                      │  (Shared Storage)│
                      └──────────────────┘
```

## Monitoring & Logging

```
┌─────────────────────────────────────────────────────┐
│                Application Containers                │
└────────────────────┬────────────────────────────────┘
                     │
                     │ Logs & Metrics
                     ▼
         ┌───────────────────────┐
         │  Logging Stack        │
         │  - Prometheus         │
         │  - Grafana           │
         │  - ELK Stack         │
         └───────────────────────┘
                     │
                     ▼
         ┌───────────────────────┐
         │   Alerts & Dashboard  │
         └───────────────────────┘
```

## Security Layers

```
┌─────────────────────────────────────────────────────┐
│  Layer 1: Firewall (GCP Firewall Rules)            │
│  - Only ports 80, 443 exposed                      │
└─────────────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────┐
│  Layer 2: Nginx (Reverse Proxy)                    │
│  - Rate limiting                                    │
│  - SSL/TLS termination                             │
└─────────────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────┐
│  Layer 3: Django (Application Security)            │
│  - CSRF protection                                  │
│  - Authentication                                   │
│  - Authorization                                    │
└─────────────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────┐
│  Layer 4: Database (Data Security)                 │
│  - Encrypted connections                            │
│  - User permissions                                 │
│  - Isolated network                                 │
└─────────────────────────────────────────────────────┘
```

This architecture demonstrates:
✓ Microservices design
✓ Scalability through replication
✓ High availability through redundancy
✓ Load balancing through Nginx
✓ Container orchestration (Swarm/K8s)
✓ Persistent data storage
✓ Caching for performance
✓ Security at multiple layers
