# Security Policy

## Overview

This repository contains provisioning scripts for setting up infrastructure components including Azure CLI, Kubernetes tools, and various system utilities. Security is a critical concern when running these scripts as they:

- Download and execute binaries from external sources
- Handle authentication tokens and credentials
- Run with elevated privileges (sudo/administrator)
- Configure system-level components

## Security Best Practices

### For Users

1. **Review Scripts Before Execution**
   - Always review the content of scripts before running them
   - Understand what each script does and what it installs
   - Check that URLs point to official sources

2. **Verify Downloads**
   - Where possible, scripts include checksum verification
   - For scripts that require manual checksum updates, obtain official hashes from vendors
   - Never skip checksum verification in production environments

3. **Secure Environment**
   - Run scripts in isolated or test environments first
   - Ensure secure network connections (avoid public WiFi)
   - Use proper access controls on systems where scripts are run

4. **Token and Credential Handling**
   - Be aware that some scripts (e.g., `azl.ps1`) handle Azure access tokens
   - Ensure logs are properly secured and not exposed
   - Clear command history after running scripts with sensitive data
   - Use Azure Managed Identities where possible instead of access tokens

5. **Keep Scripts Updated**
   - Regularly update scripts to use latest stable versions
   - Check for security advisories related to installed tools

### For Contributors

1. **Download Security**
   - Always use HTTPS for downloads
   - Implement checksum verification (SHA256 or better)
   - Pin specific versions instead of using "latest"
   - Avoid piping downloads directly to shell interpreters

2. **Temporary File Handling**
   - Use `mktemp` to create secure temporary files/directories
   - Avoid predictable paths in `/tmp`
   - Always clean up temporary files
   - Use appropriate permissions on temporary files

3. **Input Validation**
   - Validate all user inputs
   - Use quotes around variables to prevent injection
   - Sanitize inputs that could contain special characters

4. **Error Handling**
   - Implement proper error handling for all operations
   - Fail securely - don't continue after critical errors
   - Don't expose sensitive information in error messages
   - Clean up partial state on failures

5. **Privilege Management**
   - Use `sudo` only when necessary
   - Minimize the scope of privileged operations
   - Document why elevated privileges are needed

6. **GPG Key Verification**
   - Verify GPG key fingerprints when adding new repositories
   - Document expected fingerprints in code comments
   - Fail if fingerprint verification fails

## Known Security Considerations

### setup_lin_jumpbox.sh

- **Kubelogin Checksum**: Currently commented out pending version pinning. Uncomment and update hash when deploying.
- **GPG Fingerprints**: Microsoft key fingerprint is verified. Kubernetes keys should also be verified in high-security environments.
- **Version Pinning**: Helm and Kubectl versions are pinned. Update regularly but test before deploying.

### azl.ps1

- **Token Exposure**: Azure access tokens are converted to plain text for Arc initialization. This is a limitation of the Arc API.
- **Secure the execution environment and ensure logs are protected**
- **Token is cleared from memory after use but may remain in process memory**

### hpe-prep.ps1

- **Checksum Verification**: Currently disabled by default. **MUST** be enabled with official HPE checksums before production use.
- **Obtain official SHA256 hash from**: https://support.hpe.com/
- **Always verify driver authenticity before installation**

## Reporting Security Issues

If you discover a security vulnerability in these scripts:

1. **Do Not** open a public issue
2. Contact the repository maintainer privately
3. Provide detailed information about the vulnerability
4. Allow time for the issue to be addressed before public disclosure

## Security Checklist for Running Scripts

- [ ] Reviewed script content and understood what it does
- [ ] Verified all download URLs point to official sources  
- [ ] Confirmed checksums are implemented and correct (where applicable)
- [ ] Running in a secure, isolated environment
- [ ] Have backups of the system
- [ ] Network connection is secure
- [ ] Logs will be properly secured
- [ ] Credentials/tokens will be properly managed
- [ ] Have tested in non-production first

## Updates and Maintenance

- Scripts should be reviewed quarterly for security updates
- Version pins should be updated to latest stable versions
- Security advisories for installed tools should be monitored
- Checksums should be updated when versions change

## References

### Official Documentation
- [Microsoft Security Best Practices](https://docs.microsoft.com/en-us/security/)
- [Kubernetes Security](https://kubernetes.io/docs/concepts/security/)
- [Azure Security Best Practices](https://docs.microsoft.com/en-us/azure/security/)

### Security Standards
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)

### Tool-Specific Security
- [Azure CLI Security](https://docs.microsoft.com/en-us/cli/azure/security)
- [Helm Security](https://helm.sh/docs/topics/provenance/)
- [kubectl Security](https://kubernetes.io/docs/reference/kubectl/overview/#security)

## License

These security practices are provided as guidance. Users are responsible for implementing appropriate security controls for their specific environments and use cases.
