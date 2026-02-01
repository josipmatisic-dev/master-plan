# GitHub Copilot Bundle for Marine Navigation App

This bundle provides a comprehensive set of Copilot agents, instructions, and prompts specifically curated for developing the marine navigation app using Flutter/Dart. All files have been copied from the [josipmatisic-dev/awesome-copilot](https://github.com/josipmatisic-dev/awesome-copilot) repository.

## 📁 Directory Structure

```
.github/
├── agents/          # Custom Copilot agents for specialized tasks
├── instructions/    # Language and workflow-specific instructions
├── prompts/         # Reusable prompts for common development tasks
└── COPILOT_BUNDLE_README.md (this file)
```

## 🚀 What's Included

### Agents (`.github/agents/`)

Custom agents that provide specialized expertise for different aspects of development:

1. **implementation-plan.agent.md** - Creates detailed, actionable implementation plans for features
2. **task-planner.agent.md** - Generates task breakdowns and project plans based on research
3. **specification.agent.md** - Creates comprehensive technical specifications
4. **se-ux-ui-designer.agent.md** - Provides UX/UI design guidance and best practices
5. **se-technical-writer.agent.md** - Assists with creating and maintaining documentation
6. **se-security-reviewer.agent.md** - Reviews code for security vulnerabilities and compliance
7. **se-system-architecture-reviewer.agent.md** - Evaluates and provides feedback on system architecture

### Instructions (`.github/instructions/`)

Language and workflow-specific guidelines that Copilot will follow:

1. **dart-n-flutter.instructions.md** - Flutter/Dart best practices from the official teams
2. **spec-driven-workflow-v1.instructions.md** - Specification-first development workflow
3. **performance-optimization.instructions.md** - Performance optimization strategies
4. **security-and-owasp.instructions.md** - Security best practices and OWASP guidelines
5. **update-docs-on-code-change.instructions.md** - Guidelines for keeping documentation synchronized with code changes

### Prompts (`.github/prompts/`)

Reusable prompts for common development tasks:

1. **create-implementation-plan.prompt.md** - Generate implementation plans from specifications
2. **update-implementation-plan.prompt.md** - Update existing implementation plans
3. **breakdown-feature-implementation.prompt.md** - Break down features into implementable tasks
4. **breakdown-epic-pm.prompt.md** - Break down epics from a product management perspective
5. **create-specification.prompt.md** - Create detailed technical specifications
6. **documentation-writer.prompt.md** - Generate or update project documentation

## 💡 How This Supports Development

### 1. **Flutter/Dart Development**
The `dart-n-flutter.instructions.md` file ensures all Flutter code follows official best practices from the Dart and Flutter teams, covering:
- Effective Dart principles
- Architecture recommendations
- Code organization patterns
- Performance considerations

### 2. **Planning & Spec-Driven Workflow**
The spec-driven workflow tools enable a structured approach to feature development:
- Start with specifications (using `specification.agent.md`)
- Create implementation plans (using `implementation-plan.agent.md`)
- Break down into tasks (using `task-planner.agent.md`)
- Track progress systematically

### 3. **Documentation Maintenance**
Documentation tools ensure docs stay current:
- Automatic documentation updates when code changes
- Consistent documentation style
- Clear technical writing guidelines

### 4. **Performance Optimization**
Performance instructions provide:
- General optimization strategies
- Flutter-specific performance tips
- Profiling and monitoring guidance
- Memory and rendering optimization

### 5. **Security**
Security tools help build a secure application:
- OWASP Top 10 awareness
- Secure coding practices
- Security review processes
- Vulnerability identification

### 6. **UX Guidance**
UX/UI designer agent provides:
- Design best practices
- Accessibility considerations
- User experience principles
- UI consistency guidelines

### 7. **Implementation Planning**
Planning prompts help with:
- Feature breakdown and estimation
- Epic decomposition
- Task prioritization
- Implementation strategy

## 🎯 Getting Started

1. **Create a Feature**: Use `@workspace /create-specification` to start with a spec
2. **Plan Implementation**: Use the implementation-plan agent to create an actionable plan
3. **Break Down Tasks**: Use task-planner to decompose into manageable chunks
4. **Implement with Best Practices**: Dart/Flutter instructions guide code quality
5. **Maintain Documentation**: Auto-update docs as code changes
6. **Review for Security & Performance**: Use reviewer agents before finalizing

## 📚 Reference

All content sourced from: [josipmatisic-dev/awesome-copilot](https://github.com/josipmatisic-dev/awesome-copilot)

For detailed usage of each agent, instruction, or prompt, refer to the individual files in their respective directories.
