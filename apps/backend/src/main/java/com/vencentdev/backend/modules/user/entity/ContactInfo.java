package com.vencentdev.backend.modules.user.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Embeddable
@Getter
@Setter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class ContactInfo {

  @Column(name = "phone", length = 40)
  private String phone;

  @Column(name = "address_line1")
  private String addressLine1;

  @Column(name = "address_line2")
  private String addressLine2;

  @Column(name = "city", length = 120)
  private String city;

  @Column(name = "state", length = 120)
  private String state;

  @Column(name = "postal_code", length = 40)
  private String postalCode;

  @Column(name = "country", length = 2)
  private String country;
}
