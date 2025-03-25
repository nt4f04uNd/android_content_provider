### Before Contributing

1. **Open an Issue First**  
   Always open an issue to discuss your proposed change before writing code. This helps:
   - Avoid duplicate work
   - Ensure alignment with project goals
   - Discuss implementation approaches

   Issues should include:
   - Clear description of the problem/feature
   - Steps to reproduce (for bugs)
   - Screenshots (if applicable)

2. **Wait for Approval**  
   A maintainer will triage your issue and confirm if it should be implemented.

### Tests

1. **Manual Testing**  
   Due to [temporary limitations with automated testing (#17)](https://github.com/nt4f04uNd/android_content_provider/issues/17), all contributors must:
   - Launch the app in  `integration_test/` with `flutter run`
   - Verify existing tests pass

2. **Test Maintenance**  
   - Add new tests in `integration_test/` folder
   - Update relevant existing tests when changing features
