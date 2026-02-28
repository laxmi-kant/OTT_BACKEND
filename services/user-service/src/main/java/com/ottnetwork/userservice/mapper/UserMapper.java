package com.ottnetwork.userservice.mapper;

import com.ottnetwork.userservice.dto.request.CreateProfileRequest;
import com.ottnetwork.userservice.dto.request.RegisterDeviceRequest;
import com.ottnetwork.userservice.dto.response.*;
import com.ottnetwork.userservice.model.entity.*;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.ReportingPolicy;

@Mapper(componentModel = "spring", unmappedTargetPolicy = ReportingPolicy.IGNORE)
public interface UserMapper {

    UserResponse toUserResponse(User user);

    @Mapping(target = "userId", source = "user.id")
    ProfileResponse toProfileResponse(Profile profile);

    @Mapping(target = "userId", source = "user.id")
    PreferenceResponse toPreferenceResponse(Preference preference);

    DeviceResponse toDeviceResponse(Device device);

    @Mapping(target = "user", ignore = true)
    Profile toProfile(CreateProfileRequest request);

    @Mapping(target = "user", ignore = true)
    @Mapping(target = "lastActiveAt", ignore = true)
    Device toDevice(RegisterDeviceRequest request);
}
