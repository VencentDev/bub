package com.vencentdev.backend.modules.home.controller;

import static org.hamcrest.Matchers.nullValue;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.vencentdev.backend.IntegrationTestBase;
import com.vencentdev.backend.modules.home.repository.HomeDailyMomentRepository;
import com.vencentdev.backend.modules.home.repository.HomeMoodRepository;
import com.vencentdev.backend.modules.tether.entity.TetherConnection;
import com.vencentdev.backend.modules.tether.repository.TetherConnectionRepository;
import com.vencentdev.backend.modules.tether.repository.TetherInvitationRepository;
import com.vencentdev.backend.modules.user.entity.User;
import com.vencentdev.backend.modules.user.enums.KycStatus;
import com.vencentdev.backend.modules.user.enums.Role;
import com.vencentdev.backend.modules.user.enums.UserType;
import com.vencentdev.backend.modules.user.repository.UserRepository;
import java.time.LocalDate;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

class HomeControllerIntegrationTest extends IntegrationTestBase {

  @Autowired private MockMvc mockMvc;
  @Autowired private HomeDailyMomentRepository moments;
  @Autowired private HomeMoodRepository moods;
  @Autowired private TetherConnectionRepository connections;
  @Autowired private TetherInvitationRepository invitations;
  @Autowired private UserRepository users;

  @BeforeEach
  void setUp() {
    moments.deleteAll();
    moods.deleteAll();
    connections.deleteAll();
    invitations.deleteAll();
    users.deleteAll();
  }

  @Test
  void dashboardForUntetheredUserReturnsFallbackCards() throws Exception {
    users.save(user("alice", "alice@example.com", "Alice"));

    mockMvc
        .perform(get("/api/v1/home/dashboard").with(currentUser("alice")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.tether.hasActiveTether").value(false))
        .andExpect(jsonPath("$.tether.ctaLabel").value("Tether with someone"))
        .andExpect(jsonPath("$.todayMoment").value(nullValue()))
        .andExpect(jsonPath("$.latestBub.hasActivity").value(false))
        .andExpect(jsonPath("$.mood.copy").value("How are you feeling?"))
        .andExpect(jsonPath("$.mood.mood").value(nullValue()));
  }

  @Test
  void dashboardForTetheredUserReturnsPartnerCardData() throws Exception {
    User alice = users.save(user("alice", "alice@example.com", "Alice"));
    User bob = users.save(user("bob", "bob@example.com", "Bob"));
    connections.save(TetherConnection.builder().userOne(alice).userTwo(bob).active(true).build());

    mockMvc
        .perform(get("/api/v1/home/dashboard").with(currentUser("alice")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.tether.hasActiveTether").value(true))
        .andExpect(jsonPath("$.tether.partnerUserId").value(bob.getId().toString()))
        .andExpect(jsonPath("$.tether.partnerDisplayName").value("Bob"))
        .andExpect(jsonPath("$.tether.tetheredSince").exists())
        .andExpect(jsonPath("$.latestBub.copy").value("No Bubs yet"))
        .andExpect(jsonPath("$.mood.copy").value("How are you feeling?"))
        .andExpect(jsonPath("$.mood.mood").value(nullValue()));
  }

  @Test
  void dashboardRequiresAuthentication() throws Exception {
    mockMvc.perform(get("/api/v1/home/dashboard")).andExpect(status().isUnauthorized());
  }

  @Test
  void putTodayMomentCreatesAndReplacesOneMomentForTheDay() throws Exception {
    User alice = users.save(user("alice", "alice@example.com", "Alice"));
    User bob = users.save(user("bob", "bob@example.com", "Bob"));
    connections.save(TetherConnection.builder().userOne(alice).userTwo(bob).active(true).build());
    String today = LocalDate.now().toString();

    mockMvc
        .perform(putMoment("alice", "https://cdn.example.com/one.jpg", today))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.photoUrl").value("https://cdn.example.com/one.jpg"))
        .andExpect(jsonPath("$.localDate").value(today))
        .andExpect(jsonPath("$.viewerHasPostedToday").value(true));

    mockMvc
        .perform(putMoment("alice", "https://cdn.example.com/two.jpg", today))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.photoUrl").value("https://cdn.example.com/two.jpg"))
        .andExpect(jsonPath("$.localDate").value(today));

    mockMvc
        .perform(get("/api/v1/home/dashboard").with(currentUser("bob")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.todayMoment.photoUrl").value("https://cdn.example.com/two.jpg"))
        .andExpect(jsonPath("$.todayMoment.viewerHasPostedToday").value(false));
  }

  @Test
  void putMoodStoresShortMoodAndReturnsItOnDashboard() throws Exception {
    users.save(user("alice", "alice@example.com", "Alice"));

    mockMvc
        .perform(putMood("alice", "cozy"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.copy").value("How are you feeling?"))
        .andExpect(jsonPath("$.mood").value("cozy"));

    mockMvc
        .perform(get("/api/v1/home/dashboard").with(currentUser("alice")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.mood.mood").value("cozy"));
  }

  @Test
  void dashboardForTetheredUserReturnsViewerMoodOnly() throws Exception {
    User alice = users.save(user("alice", "alice@example.com", "Alice"));
    User bob = users.save(user("bob", "bob@example.com", "Bob"));
    connections.save(TetherConnection.builder().userOne(alice).userTwo(bob).active(true).build());

    mockMvc.perform(putMood("alice", "calm")).andExpect(status().isOk());
    mockMvc.perform(putMood("bob", "sparkly")).andExpect(status().isOk());

    mockMvc
        .perform(get("/api/v1/home/dashboard").with(currentUser("alice")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.mood.mood").value("calm"));
  }

  @Test
  void putMoodRejectsMoodLongerThanTwentyCharacters() throws Exception {
    users.save(user("alice", "alice@example.com", "Alice"));

    mockMvc
        .perform(putMood("alice", "this mood is way too long"))
        .andExpect(status().isBadRequest());
  }

  @Test
  void partnerCanReactToTodayMomentWithHeart() throws Exception {
    User alice = users.save(user("alice", "alice@example.com", "Alice"));
    User bob = users.save(user("bob", "bob@example.com", "Bob"));
    connections.save(TetherConnection.builder().userOne(alice).userTwo(bob).active(true).build());
    String today = LocalDate.now().toString();

    String body =
        mockMvc
            .perform(putMoment("alice", "https://cdn.example.com/one.jpg", today))
            .andExpect(status().isOk())
            .andReturn()
            .getResponse()
            .getContentAsString();
    String momentId = body.replaceAll(".*\"momentId\":\"([^\"]+)\".*", "$1");

    mockMvc
        .perform(
            post("/api/v1/home/today-moment/{momentId}/reaction", momentId)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"reaction\":\"❤️\"}")
                .with(currentUser("bob")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.partnerReaction").value("❤️"));
  }

  @Test
  void creatorCannotReactToOwnMoment() throws Exception {
    User alice = users.save(user("alice", "alice@example.com", "Alice"));
    User bob = users.save(user("bob", "bob@example.com", "Bob"));
    connections.save(TetherConnection.builder().userOne(alice).userTwo(bob).active(true).build());
    String today = LocalDate.now().toString();

    String body =
        mockMvc
            .perform(putMoment("alice", "https://cdn.example.com/one.jpg", today))
            .andExpect(status().isOk())
            .andReturn()
            .getResponse()
            .getContentAsString();
    String momentId = body.replaceAll(".*\"momentId\":\"([^\"]+)\".*", "$1");

    mockMvc
        .perform(
            post("/api/v1/home/today-moment/{momentId}/reaction", momentId)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"reaction\":\"❤️\"}")
                .with(currentUser("alice")))
        .andExpect(status().isBadRequest());
  }

  private org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder putMoment(
      String subject, String photoUrl, String localDate) {
    return put("/api/v1/home/today-moment")
        .contentType(MediaType.APPLICATION_JSON)
        .content("{\"photoUrl\":\"" + photoUrl + "\",\"localDate\":\"" + localDate + "\"}")
        .with(currentUser(subject));
  }

  private org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder putMood(
      String subject, String mood) {
    return put("/api/v1/home/mood")
        .contentType(MediaType.APPLICATION_JSON)
        .content("{\"mood\":\"" + mood + "\"}")
        .with(currentUser(subject));
  }

  private org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors
          .JwtRequestPostProcessor
      currentUser(String subject) {
    return jwt()
        .jwt(
            token ->
                token
                    .subject(subject)
                    .claim("email", subject + "@example.com")
                    .claim("name", subject))
        .authorities(() -> "ROLE_USER");
  }

  private User user(String externalId, String email, String displayName) {
    return User.builder()
        .externalId(externalId)
        .email(email)
        .displayName(displayName)
        .role(Role.USER)
        .userType(UserType.INDIVIDUAL)
        .kycStatus(KycStatus.NONE)
        .build();
  }
}
