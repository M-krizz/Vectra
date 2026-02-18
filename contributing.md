# Contributing to Vectra

:+1::tada: First off, thanks for taking the time to contribute to **Vectra**! :tada::+1:

We welcome pull requests, bug reports, feature suggestions, and documentation improvements. The following is a set of guidelines for contributing to Vectra — a modern ride-sharing platform. These are mostly guidelines, not rules. Use your best judgment, and feel free to propose changes to this document in a pull request.

---

## How Can I Contribute?

There are lots of ways to get involved. Here are some suggestions of things we'd love help with.

### Reporting Bugs :bug:

If you find a bug, please [open an issue](../../issues/new) and include as much detail as possible:

- **Use a clear and descriptive title** for the issue to identify the problem.
- **Describe the exact steps to reproduce the problem** in as much detail as possible — include the commands you ran, the screens you navigated, etc.
- **Provide specific examples.** Include code snippets, screenshots, or links using [Markdown code blocks](https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax#quoting-code).
- **Describe the behavior you observed** and explain what you expected instead.
- **Include your environment details:** OS, Node.js version, Flutter/Dart version, Docker version, and database version.

### Suggesting Features :sparkles:

Feature requests are welcome! Please open an issue with the **enhancement** label and describe:

- The use case and why the feature would be valuable.
- How you envision it working from a user's perspective.
- Any technical considerations or constraints you're aware of.

### Resolving Existing Issues

Browse our [open issues](../../issues) — look for the **"help wanted"** or **"good first issue"** labels for beginner-friendly tasks.

### Improving Documentation

We welcome contributions that improve documentation — whether it's fixing typos, adding missing info, or making things clearer and more consistent.

---

## Getting Started

### Prerequisites

Make sure you have the following installed on your machine:

| Tool       | Version   | Purpose                            |
|------------|-----------|------------------------------------|
| **Node.js**    | >= 18.x   | Backend runtime                    |
| **npm**        | >= 9.x    | Package management                 |
| **Docker** & **Docker Compose** | Latest | PostgreSQL + Redis containers |
| **Flutter**    | >= 3.x    | Frontend mobile & web apps         |
| **Git**        | Latest    | Version control                    |

### Dev Environment Setup

1. **Clone the repository**

   ```bash
   git clone https://github.com/<your-org>/Vectra.git
   cd Vectra/VectraApp
   ```

2. **Start infrastructure services** (PostgreSQL with PostGIS + Redis)

   ```bash
   docker-compose up -d
   ```

   This starts:
   - **PostgreSQL** on port `5433` (user: `vectra`, password: `vectra_pass`, db: `vectra_db`)
   - **Redis** on port `6379`

3. **Set up the backend**

   ```bash
   cd backend
   npm install
   ```

   Create a `.env` file in the `backend/` directory with the required environment variables (refer to `DATABASE_README.md` for database configuration details).

   ```bash
   # Start in development mode (with hot-reload)
   npm run start:dev
   ```

4. **Set up the frontend** (Driver / Rider App)

   ```bash
   cd frontend/driver_app   # or frontend/rider_app
   flutter pub get
   flutter run
   ```

5. **Run database migrations**

   ```bash
   cd backend
   npm run migration:run
   ```

6. **Run tests**

   ```bash
   cd backend
   npm test
   ```

---

## Project Structure

```
VectraApp/
├── backend/                  # NestJS backend API
│   ├── src/
│   │   ├── modules/          # Feature modules
│   │   │   ├── Authentication/   # Auth, JWT, OTP, RBAC
│   │   │   ├── ride_requests/    # Ride request management
│   │   │   ├── trips/            # Trip lifecycle
│   │   │   ├── safety/           # Safety & incident management
│   │   │   ├── chat/             # In-app messaging
│   │   │   ├── location/         # Location tracking
│   │   │   └── pooling/          # Ride pooling
│   │   ├── database/         # TypeORM config, migrations, data-source
│   │   ├── realtime/         # WebSocket / Socket.IO gateways
│   │   ├── common/           # Shared guards, decorators, utilities
│   │   └── main.ts           # Application entry point
│   └── package.json
├── frontend/
│   ├── driver_app/           # Flutter driver application
│   ├── rider_app/            # Flutter rider application
│   ├── admin_web/            # Admin web dashboard
│   └── shared/               # Shared frontend utilities
├── docs/                     # Project documentation
├── docker-compose.yml        # Infrastructure services
└── DATABASE_README.md        # Database setup guide
```

---

## Style Guide & Coding Conventions

### General

- Use **2-space indentation** across all files.
- Ensure a **trailing newline** at the end of every file.
- Remove **unused imports** and **dead code** before committing.
- Write **meaningful variable and function names** — clarity over brevity.

### Backend (NestJS / TypeScript)

- Follow the [NestJS best practices](https://docs.nestjs.com/) and modular architecture.
- Use **DTOs** (Data Transfer Objects) with `class-validator` decorators for all request payloads.
- Use **TypeORM entities** for database models — never write raw SQL unless absolutely necessary.
- Format code with **Prettier** before committing:

  ```bash
  npm run format
  ```

- Lint your code with **ESLint**:

  ```bash
  npm run lint
  ```

- Write **unit tests** using **Jest** for all services and controllers:

  ```bash
  npm test
  ```

### Frontend (Flutter / Dart)

- Follow the [Dart style guide](https://dart.dev/effective-dart/style) and Flutter conventions.
- Keep widgets modular and reusable.
- Use state management patterns consistently across the app.
- Run `flutter analyze` to check for issues before submitting.

---

## Pull Requests

### Before Creating a Pull Request

- [ ] Your code compiles and runs without errors.
- [ ] You've included or updated tests for your changes.
- [ ] You've run `npm run lint` and `npm run format` (backend).
- [ ] You've run `flutter analyze` (frontend).
- [ ] You've manually tested your changes.
- [ ] Your branch is rebased on top of the latest `main` branch.

### How to Create a Pull Request

1. **Create a new branch** from `main`:

   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** and commit them following our [commit message conventions](#commit-messages):

   ```bash
   git add .
   git commit -m "feat: add ride cancellation endpoint"
   ```

3. **Rebase on the latest `main`** before pushing:

   ```bash
   git fetch origin
   git rebase origin/main
   ```

4. **Run all checks**:

   ```bash
   # Backend
   cd backend
   npm run lint
   npm test

   # Frontend (if applicable)
   cd frontend/driver_app
   flutter analyze
   flutter test
   ```

5. **Push your branch** and open a pull request:

   ```bash
   git push origin feature/your-feature-name
   ```

6. Open a **Pull Request** on GitHub, fill in the PR template, and request a review.

### Commit Messages

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

- **Format**: `<type>(<scope>): <short description>`
- **Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `perf`, `ci`
- Use the **present tense** ("Add feature" not "Added feature").
- Use the **imperative mood** ("Move cursor to..." not "Moves cursor to...").
- Limit the first line to **72 characters** or less.
- Reference issues in the body when applicable.

#### Examples

```
feat(auth): add OTP verification endpoint

Implement OTP verification flow with configurable expiry
and rate limiting support.

Closes #42
```

```
fix(trips): resolve fare calculation rounding error

Fixes #78
```

```
docs: update database setup instructions
```

> **Note:** Add co-authors to your commit message for commits with multiple contributors:
>
> ```
> Co-authored-by: Name <email@example.com>
> ```

---

## Code of Conduct

We are committed to providing a welcoming and inclusive experience for everyone. Please be respectful, constructive, and professional in all interactions.

By participating in this project, you agree to abide by our standards of conduct. If you experience or witness unacceptable behavior, please report it to the project maintainers.

---

## Developer's Certificate of Origin 1.1

By making a contribution to this project, I certify that:

- (a) The contribution was created in whole or in part by me and I have the right to submit it under the open source license indicated in the file; or
- (b) The contribution is based upon previous work that, to the best of my knowledge, is covered under an appropriate open source license and I have the right under that license to submit that work with modifications, whether created in whole or in part by me, under the same open source license (unless I am permitted to submit under a different license), as indicated in the file; or
- (c) The contribution was provided directly to me by some other person who certified (a), (b), or (c) and I have not modified it.
- (d) I understand and agree that this project and the contribution are public and that a record of the contribution (including all personal information I submit with it, including my sign-off) is maintained indefinitely and may be redistributed consistent with this project or the open source license(s) involved.

---

**Thank you for contributing to Vectra!** :heart:
