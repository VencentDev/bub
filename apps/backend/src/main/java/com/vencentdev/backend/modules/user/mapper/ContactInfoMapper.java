package com.vencentdev.backend.modules.user.mapper;

import com.vencentdev.backend.modules.user.entity.ContactInfo;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface ContactInfoMapper {
  ContactInfo copy(ContactInfo contactInfo);
}
