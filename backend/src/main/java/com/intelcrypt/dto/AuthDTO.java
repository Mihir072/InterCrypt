package com.intelcrypt.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.Arrays;
import java.util.Objects;

/**
 * Authentication request/response DTOs.
 */
public class AuthDTO {

    public static class RegisterRequest {
        @NotBlank(message = "Username is required")
        @Size(min = 3, max = 50, message = "Username must be between 3 and 50 characters")
        private String username;

        @NotBlank(message = "Email is required")
        @Email(message = "Invalid email format")
        private String email;

        @NotBlank(message = "Password is required")
        @Size(min = 8, message = "Password must be at least 8 characters")
        private String password;

        public RegisterRequest() {}

        public RegisterRequest(String username, String email, String password) {
            this.username = username;
            this.email = email;
            this.password = password;
        }

        public String getUsername() {
            return username;
        }

        public void setUsername(String username) {
            this.username = username;
        }

        public String getEmail() {
            return email;
        }

        public void setEmail(String email) {
            this.email = email;
        }

        public String getPassword() {
            return password;
        }

        public void setPassword(String password) {
            this.password = password;
        }

        @Override
        public String toString() {
            return "RegisterRequest{" + "username='" + username + '\'' + ", email='" + email + '\'' + '}';
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (o == null || getClass() != o.getClass()) return false;
            RegisterRequest that = (RegisterRequest) o;
            return Objects.equals(username, that.username) && Objects.equals(email, that.email);
        }

        @Override
        public int hashCode() {
            return Objects.hash(username, email);
        }

        public static Builder builder() {
            return new Builder();
        }

        public static class Builder {
            private String username;
            private String email;
            private String password;

            public Builder username(String username) {
                this.username = username;
                return this;
            }

            public Builder email(String email) {
                this.email = email;
                return this;
            }

            public Builder password(String password) {
                this.password = password;
                return this;
            }

            public RegisterRequest build() {
                return new RegisterRequest(username, email, password);
            }
        }
    }

    public static class LoginRequest {
        @NotBlank(message = "Username is required")
        private String username;

        @NotBlank(message = "Password is required")
        private String password;

        public LoginRequest() {}

        public LoginRequest(String username, String password) {
            this.username = username;
            this.password = password;
        }

        public String getUsername() {
            return username;
        }

        public void setUsername(String username) {
            this.username = username;
        }

        public String getPassword() {
            return password;
        }

        public void setPassword(String password) {
            this.password = password;
        }

        @Override
        public String toString() {
            return "LoginRequest{" + "username='" + username + '\'' + '}';
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (o == null || getClass() != o.getClass()) return false;
            LoginRequest that = (LoginRequest) o;
            return Objects.equals(username, that.username);
        }

        @Override
        public int hashCode() {
            return Objects.hash(username);
        }

        public static Builder builder() {
            return new Builder();
        }

        public static class Builder {
            private String username;
            private String password;

            public Builder username(String username) {
                this.username = username;
                return this;
            }

            public Builder password(String password) {
                this.password = password;
                return this;
            }

            public LoginRequest build() {
                return new LoginRequest(username, password);
            }
        }
    }

    public static class RefreshTokenRequest {
        @NotBlank(message = "Refresh token is required")
        private String refreshToken;

        public RefreshTokenRequest() {}

        public RefreshTokenRequest(String refreshToken) {
            this.refreshToken = refreshToken;
        }

        public String getRefreshToken() {
            return refreshToken;
        }

        public void setRefreshToken(String refreshToken) {
            this.refreshToken = refreshToken;
        }

        @Override
        public String toString() {
            return "RefreshTokenRequest{}";
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (o == null || getClass() != o.getClass()) return false;
            RefreshTokenRequest that = (RefreshTokenRequest) o;
            return Objects.equals(refreshToken, that.refreshToken);
        }

        @Override
        public int hashCode() {
            return Objects.hash(refreshToken);
        }

        public static Builder builder() {
            return new Builder();
        }

        public static class Builder {
            private String refreshToken;

            public Builder refreshToken(String refreshToken) {
                this.refreshToken = refreshToken;
                return this;
            }

            public RefreshTokenRequest build() {
                return new RefreshTokenRequest(refreshToken);
            }
        }
    }

    public static class ChangePasswordRequest {
        @NotBlank(message = "Current password is required")
        private String currentPassword;

        @NotBlank(message = "New password is required")
        @Size(min = 8, message = "New password must be at least 8 characters")
        private String newPassword;

        public ChangePasswordRequest() {}

        public ChangePasswordRequest(String currentPassword, String newPassword) {
            this.currentPassword = currentPassword;
            this.newPassword = newPassword;
        }

        public String getCurrentPassword() {
            return currentPassword;
        }

        public void setCurrentPassword(String currentPassword) {
            this.currentPassword = currentPassword;
        }

        public String getNewPassword() {
            return newPassword;
        }

        public void setNewPassword(String newPassword) {
            this.newPassword = newPassword;
        }

        @Override
        public String toString() {
            return "ChangePasswordRequest{}";
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (o == null || getClass() != o.getClass()) return false;
            ChangePasswordRequest that = (ChangePasswordRequest) o;
            return Objects.equals(currentPassword, that.currentPassword) &&
                    Objects.equals(newPassword, that.newPassword);
        }

        @Override
        public int hashCode() {
            return Objects.hash(currentPassword, newPassword);
        }

        public static Builder builder() {
            return new Builder();
        }

        public static class Builder {
            private String currentPassword;
            private String newPassword;

            public Builder currentPassword(String currentPassword) {
                this.currentPassword = currentPassword;
                return this;
            }

            public Builder newPassword(String newPassword) {
                this.newPassword = newPassword;
                return this;
            }

            public ChangePasswordRequest build() {
                return new ChangePasswordRequest(currentPassword, newPassword);
            }
        }
    }

    public static class AuthResponse {
        private String accessToken;
        private String refreshToken;
        private String tokenType;
        private Long expiresIn;
        private UserInfo user;

        public AuthResponse() {}

        public AuthResponse(String accessToken, String refreshToken, String tokenType, Long expiresIn, UserInfo user) {
            this.accessToken = accessToken;
            this.refreshToken = refreshToken;
            this.tokenType = tokenType;
            this.expiresIn = expiresIn;
            this.user = user;
        }

        public String getAccessToken() {
            return accessToken;
        }

        public void setAccessToken(String accessToken) {
            this.accessToken = accessToken;
        }

        public String getRefreshToken() {
            return refreshToken;
        }

        public void setRefreshToken(String refreshToken) {
            this.refreshToken = refreshToken;
        }

        public String getTokenType() {
            return tokenType;
        }

        public void setTokenType(String tokenType) {
            this.tokenType = tokenType;
        }

        public Long getExpiresIn() {
            return expiresIn;
        }

        public void setExpiresIn(Long expiresIn) {
            this.expiresIn = expiresIn;
        }

        public UserInfo getUser() {
            return user;
        }

        public void setUser(UserInfo user) {
            this.user = user;
        }

        @Override
        public String toString() {
            return "AuthResponse{" + "tokenType='" + tokenType + '\'' + ", expiresIn=" + expiresIn + '}';
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (o == null || getClass() != o.getClass()) return false;
            AuthResponse that = (AuthResponse) o;
            return Objects.equals(accessToken, that.accessToken) &&
                    Objects.equals(refreshToken, that.refreshToken) &&
                    Objects.equals(tokenType, that.tokenType) &&
                    Objects.equals(expiresIn, that.expiresIn) &&
                    Objects.equals(user, that.user);
        }

        @Override
        public int hashCode() {
            return Objects.hash(accessToken, refreshToken, tokenType, expiresIn, user);
        }

        public static Builder builder() {
            return new Builder();
        }

        public static class Builder {
            private String accessToken;
            private String refreshToken;
            private String tokenType;
            private Long expiresIn;
            private UserInfo user;

            public Builder accessToken(String accessToken) {
                this.accessToken = accessToken;
                return this;
            }

            public Builder refreshToken(String refreshToken) {
                this.refreshToken = refreshToken;
                return this;
            }

            public Builder tokenType(String tokenType) {
                this.tokenType = tokenType;
                return this;
            }

            public Builder expiresIn(Long expiresIn) {
                this.expiresIn = expiresIn;
                return this;
            }

            public Builder user(UserInfo user) {
                this.user = user;
                return this;
            }

            public AuthResponse build() {
                return new AuthResponse(accessToken, refreshToken, tokenType, expiresIn, user);
            }
        }
    }

    public static class UserInfo {
        private String id;
        private String username;
        private String email;
        private String[] roles;
        private String clearanceLevel;

        public UserInfo() {}

        public UserInfo(String id, String username, String email, String[] roles, String clearanceLevel) {
            this.id = id;
            this.username = username;
            this.email = email;
            this.roles = roles;
            this.clearanceLevel = clearanceLevel;
        }

        public String getId() {
            return id;
        }

        public void setId(String id) {
            this.id = id;
        }

        public String getUsername() {
            return username;
        }

        public void setUsername(String username) {
            this.username = username;
        }

        public String getEmail() {
            return email;
        }

        public void setEmail(String email) {
            this.email = email;
        }

        public String[] getRoles() {
            return roles;
        }

        public void setRoles(String[] roles) {
            this.roles = roles;
        }

        public String getClearanceLevel() {
            return clearanceLevel;
        }

        public void setClearanceLevel(String clearanceLevel) {
            this.clearanceLevel = clearanceLevel;
        }

        @Override
        public String toString() {
            return "UserInfo{" + "id='" + id + '\'' + ", username='" + username + '\'' + ", email='" + email + '\'' + '}';
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (o == null || getClass() != o.getClass()) return false;
            UserInfo that = (UserInfo) o;
            return Objects.equals(id, that.id) && Objects.equals(username, that.username) &&
                    Objects.equals(email, that.email) && Arrays.equals(roles, that.roles) &&
                    Objects.equals(clearanceLevel, that.clearanceLevel);
        }

        @Override
        public int hashCode() {
            int result = Objects.hash(id, username, email, clearanceLevel);
            result = 31 * result + Arrays.hashCode(roles);
            return result;
        }

        public static Builder builder() {
            return new Builder();
        }

        public static class Builder {
            private String id;
            private String username;
            private String email;
            private String[] roles;
            private String clearanceLevel;

            public Builder id(String id) {
                this.id = id;
                return this;
            }

            public Builder username(String username) {
                this.username = username;
                return this;
            }

            public Builder email(String email) {
                this.email = email;
                return this;
            }

            public Builder roles(String[] roles) {
                this.roles = roles;
                return this;
            }

            public Builder clearanceLevel(String clearanceLevel) {
                this.clearanceLevel = clearanceLevel;
                return this;
            }

            public UserInfo build() {
                return new UserInfo(id, username, email, roles, clearanceLevel);
            }
        }
    }
}
