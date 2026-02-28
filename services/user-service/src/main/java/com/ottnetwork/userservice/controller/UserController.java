package com.ottnetwork.userservice.controller;

import com.ottnetwork.common.dto.ApiResponse;
import com.ottnetwork.common.dto.PagedResponse;
import com.ottnetwork.security.AuthenticatedUser;
import com.ottnetwork.userservice.dto.request.*;
import com.ottnetwork.userservice.dto.response.*;
import com.ottnetwork.userservice.service.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
@Tag(name = "Users", description = "User profile, preferences, and device management")
public class UserController {

    private final UserService userService;
    private final ProfileService profileService;
    private final PreferenceService preferenceService;
    private final DeviceService deviceService;

    // ==================== User endpoints ====================

    @GetMapping("/me")
    @Operation(summary = "Get current user's details")
    public ResponseEntity<ApiResponse<UserResponse>> getCurrentUser() {
        AuthenticatedUser auth = AuthenticatedUser.fromSecurityContext();
        UserResponse response = userService.getUserByAuthUserId(auth.id());
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @PutMapping("/me")
    @Operation(summary = "Update current user's details")
    public ResponseEntity<ApiResponse<UserResponse>> updateCurrentUser(@Valid @RequestBody UpdateUserRequest request) {
        AuthenticatedUser auth = AuthenticatedUser.fromSecurityContext();
        UserResponse currentUser = userService.getUserByAuthUserId(auth.id());
        UserResponse response = userService.updateUser(currentUser.getId(), request);
        return ResponseEntity.ok(ApiResponse.success(response, "User updated successfully"));
    }

    @GetMapping("/{userId}")
    @Operation(summary = "Get user by ID")
    public ResponseEntity<ApiResponse<UserResponse>> getUserById(@PathVariable UUID userId) {
        UserResponse response = userService.getUserById(userId);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @GetMapping
    @Operation(summary = "Get all active users (paginated)")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<PagedResponse<UserResponse>>> getAllUsers(
            @PageableDefault(size = 20) Pageable pageable) {
        PagedResponse<UserResponse> response = userService.getAllUsers(pageable);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @DeleteMapping("/me")
    @Operation(summary = "Deactivate current user's account")
    public ResponseEntity<ApiResponse<Void>> deactivateCurrentUser() {
        AuthenticatedUser auth = AuthenticatedUser.fromSecurityContext();
        UserResponse currentUser = userService.getUserByAuthUserId(auth.id());
        userService.deactivateUser(currentUser.getId());
        return ResponseEntity.ok(ApiResponse.success(null, "Account deactivated successfully"));
    }

    // ==================== Profile endpoints ====================

    @GetMapping("/me/profiles")
    @Operation(summary = "Get current user's profiles")
    public ResponseEntity<ApiResponse<List<ProfileResponse>>> getMyProfiles() {
        AuthenticatedUser auth = AuthenticatedUser.fromSecurityContext();
        UserResponse currentUser = userService.getUserByAuthUserId(auth.id());
        List<ProfileResponse> response = profileService.getProfilesByUserId(currentUser.getId());
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @PostMapping("/me/profiles")
    @Operation(summary = "Create a new profile for current user")
    public ResponseEntity<ApiResponse<ProfileResponse>> createProfile(@Valid @RequestBody CreateProfileRequest request) {
        AuthenticatedUser auth = AuthenticatedUser.fromSecurityContext();
        UserResponse currentUser = userService.getUserByAuthUserId(auth.id());
        ProfileResponse response = profileService.createProfile(currentUser.getId(), request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(response, "Profile created successfully"));
    }

    @PutMapping("/me/profiles/{profileId}")
    @Operation(summary = "Update a profile")
    public ResponseEntity<ApiResponse<ProfileResponse>> updateProfile(
            @PathVariable UUID profileId,
            @Valid @RequestBody UpdateProfileRequest request) {
        ProfileResponse response = profileService.updateProfile(profileId, request);
        return ResponseEntity.ok(ApiResponse.success(response, "Profile updated successfully"));
    }

    @DeleteMapping("/me/profiles/{profileId}")
    @Operation(summary = "Delete a profile")
    public ResponseEntity<ApiResponse<Void>> deleteProfile(@PathVariable UUID profileId) {
        profileService.deleteProfile(profileId);
        return ResponseEntity.ok(ApiResponse.success(null, "Profile deleted successfully"));
    }

    // ==================== Preference endpoints ====================

    @GetMapping("/me/preferences")
    @Operation(summary = "Get current user's preferences")
    public ResponseEntity<ApiResponse<PreferenceResponse>> getMyPreferences() {
        AuthenticatedUser auth = AuthenticatedUser.fromSecurityContext();
        UserResponse currentUser = userService.getUserByAuthUserId(auth.id());
        PreferenceResponse response = preferenceService.getPreferencesByUserId(currentUser.getId());
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @PutMapping("/me/preferences")
    @Operation(summary = "Update current user's preferences")
    public ResponseEntity<ApiResponse<PreferenceResponse>> updateMyPreferences(
            @Valid @RequestBody UpdatePreferenceRequest request) {
        AuthenticatedUser auth = AuthenticatedUser.fromSecurityContext();
        UserResponse currentUser = userService.getUserByAuthUserId(auth.id());
        PreferenceResponse response = preferenceService.updatePreferences(currentUser.getId(), request);
        return ResponseEntity.ok(ApiResponse.success(response, "Preferences updated successfully"));
    }

    // ==================== Device endpoints ====================

    @GetMapping("/me/devices")
    @Operation(summary = "Get current user's registered devices")
    public ResponseEntity<ApiResponse<List<DeviceResponse>>> getMyDevices() {
        AuthenticatedUser auth = AuthenticatedUser.fromSecurityContext();
        UserResponse currentUser = userService.getUserByAuthUserId(auth.id());
        List<DeviceResponse> response = deviceService.getDevicesByUserId(currentUser.getId());
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @PostMapping("/me/devices")
    @Operation(summary = "Register a device for current user")
    public ResponseEntity<ApiResponse<DeviceResponse>> registerDevice(
            @Valid @RequestBody RegisterDeviceRequest request) {
        AuthenticatedUser auth = AuthenticatedUser.fromSecurityContext();
        UserResponse currentUser = userService.getUserByAuthUserId(auth.id());
        DeviceResponse response = deviceService.registerDevice(currentUser.getId(), request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(response, "Device registered successfully"));
    }

    @DeleteMapping("/me/devices/{deviceId}")
    @Operation(summary = "Remove a registered device")
    public ResponseEntity<ApiResponse<Void>> removeDevice(@PathVariable String deviceId) {
        AuthenticatedUser auth = AuthenticatedUser.fromSecurityContext();
        UserResponse currentUser = userService.getUserByAuthUserId(auth.id());
        deviceService.removeDevice(currentUser.getId(), deviceId);
        return ResponseEntity.ok(ApiResponse.success(null, "Device removed successfully"));
    }
}
