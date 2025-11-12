# Contributing to Elevate Learning

Thank you for your interest in contributing to Elevate Learning! This document provides guidelines for contributing to this project.

## 📋 Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on what's best for the community
- Show empathy towards others

## 🚀 Getting Started

### Prerequisites

Before contributing, ensure you have:
- Git installed
- Docker and Kubernetes knowledge
- Python 3.12+ and Django experience
- Access to a Kubernetes cluster (K3s recommended)

### Setting Up Development Environment

1. **Fork the repository**
   ```bash
   # Click "Fork" on GitHub, then clone your fork
   git clone https://github.com/YOUR_USERNAME/elevate-learning-k8s.git
   cd elevate-learning-k8s
   ```

2. **Create a virtual environment**
   ```bash
   cd elevatelearning
   python3 -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   pip install -r requirements.txt
   ```

3. **Copy environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your local settings
   ```

4. **Run migrations**
   ```bash
   python manage.py migrate
   python manage.py createsuperuser
   python manage.py runserver
   ```

## 🔀 Contribution Workflow

### 1. Create a Branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-bug-fix
```

Branch naming conventions:
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation updates
- `refactor/` - Code refactoring
- `test/` - Test additions/improvements

### 2. Make Your Changes

- Write clean, readable code
- Follow PEP 8 style guide for Python
- Add comments for complex logic
- Update documentation if needed

### 3. Test Your Changes

```bash
# Run Django tests
python manage.py test

# Test Docker build
docker build -t elevatelearning-web:test .

# Test Kubernetes deployment (if applicable)
kubectl apply -f k8s/ --dry-run=client
```

### 4. Commit Your Changes

Follow conventional commit format:

```bash
git add .
git commit -m "feat: add user profile picture upload"
# or
git commit -m "fix: resolve CSRF token validation issue"
# or
git commit -m "docs: update deployment instructions"
```

Commit types:
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation
- `style:` - Formatting (no code change)
- `refactor:` - Code refactoring
- `test:` - Adding tests
- `chore:` - Maintenance tasks

### 5. Push and Create Pull Request

```bash
git push origin feature/your-feature-name
```

Then:
1. Go to GitHub repository
2. Click "Compare & pull request"
3. Fill in the PR template
4. Link related issues (if any)
5. Request review

## 📝 Pull Request Guidelines

### PR Title Format
```
[Type] Brief description
```

Examples:
- `[Feature] Add email notification for course completion`
- `[Fix] Resolve database connection timeout`
- `[Docs] Update K3s installation guide`

### PR Description Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Refactoring
- [ ] Performance improvement

## Testing
- [ ] Tests added/updated
- [ ] Manual testing completed
- [ ] Kubernetes deployment tested

## Screenshots (if applicable)
Add screenshots here

## Related Issues
Fixes #123
```

## 🧪 Testing Requirements

All contributions should include:

1. **Unit Tests** (for new features)
   ```python
   # elevatelearningapp/tests.py
   from django.test import TestCase
   
   class YourTestCase(TestCase):
       def test_your_feature(self):
           # Test code here
           pass
   ```

2. **Integration Tests** (for API endpoints)
3. **Manual Testing** (for UI changes)
4. **Kubernetes Testing** (for deployment changes)

## 📋 Code Style Guidelines

### Python/Django
- Follow PEP 8
- Use meaningful variable names
- Keep functions focused and small
- Add docstrings for classes and functions

```python
def calculate_course_progress(user, course):
    """
    Calculate the completion percentage for a user in a course.
    
    Args:
        user (User): The user object
        course (Course): The course object
        
    Returns:
        float: Completion percentage (0-100)
    """
    # Implementation here
    pass
```

### Kubernetes YAML
- Use 2-space indentation
- Include resource limits
- Add descriptive labels
- Use comments for complex configurations

### Documentation
- Use Markdown format
- Include code examples
- Add screenshots for UI features
- Keep language clear and concise

## 🐛 Bug Reports

When reporting bugs, include:

1. **Description**: Clear description of the bug
2. **Steps to Reproduce**: Step-by-step instructions
3. **Expected Behavior**: What should happen
4. **Actual Behavior**: What actually happens
5. **Environment**: 
   - OS and version
   - Python version
   - Django version
   - Kubernetes version
6. **Logs**: Relevant error logs
7. **Screenshots**: If applicable

## 💡 Feature Requests

When suggesting features:

1. **Use Case**: Describe the problem you're solving
2. **Proposed Solution**: How you envision the feature
3. **Alternatives**: Other solutions you considered
4. **Implementation Details**: Technical approach (if applicable)

## 🔒 Security Issues

**DO NOT** open public issues for security vulnerabilities.

Instead:
1. Email: [your-email@example.com]
2. Use GitHub Security Advisories (private)
3. Provide detailed description and steps to reproduce

## 📚 Documentation

Help improve documentation by:
- Fixing typos and grammar
- Adding examples
- Clarifying confusing sections
- Translating to other languages
- Creating video tutorials

## 🎯 Areas for Contribution

### High Priority
- [ ] Add automated testing (pytest, coverage)
- [ ] Implement CI/CD pipeline (GitHub Actions)
- [ ] Add monitoring (Prometheus, Grafana)
- [ ] Improve error handling
- [ ] Add API documentation (Swagger/OpenAPI)

### Medium Priority
- [ ] Add multi-language support (i18n)
- [ ] Implement caching (Redis)
- [ ] Add file upload for course materials
- [ ] Create mobile-responsive UI improvements
- [ ] Add email notifications

### Nice to Have
- [ ] Dark mode for UI
- [ ] Advanced analytics dashboard
- [ ] Integration with external LMS tools
- [ ] Video streaming support
- [ ] Real-time chat/messaging

## 📞 Getting Help

- **Documentation**: Check [docs](All_mds/)
- **Issues**: Search existing issues
- **Discussions**: Start a GitHub discussion
- **Questions**: Open an issue with `question` label

## 🙏 Recognition

Contributors will be:
- Listed in CONTRIBUTORS.md
- Mentioned in release notes
- Acknowledged in project documentation

Thank you for contributing! 🎉
