package com.vencentdev.backend.modules.home.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.nullValue;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.vencentdev.backend.IntegrationTestBase;
import com.vencentdev.backend.modules.bub.entity.BubEvent;
import com.vencentdev.backend.modules.bub.repository.BubEventRepository;
import com.vencentdev.backend.modules.home.entity.HomeDailyMoment;
import com.vencentdev.backend.modules.home.entity.HomeMood;
import com.vencentdev.backend.modules.home.repository.HomeDailyMomentRepository;
import com.vencentdev.backend.modules.home.repository.HomeMoodRepository;
import com.vencentdev.backend.modules.home.service.HomeMomentExpiryCleanupService;
import com.vencentdev.backend.modules.home.service.MomentStorageService;
import com.vencentdev.backend.modules.home.service.MomentStorageService.StoredMomentPhoto;
import com.vencentdev.backend.modules.tether.entity.TetherConnection;
import com.vencentdev.backend.modules.tether.repository.TetherConnectionRepository;
import com.vencentdev.backend.modules.tether.repository.TetherInvitationRepository;
import com.vencentdev.backend.modules.user.entity.User;
import com.vencentdev.backend.modules.user.enums.KycStatus;
import com.vencentdev.backend.modules.user.enums.Role;
import com.vencentdev.backend.modules.user.enums.UserType;
import com.vencentdev.backend.modules.user.repository.UserRepository;
import java.sql.Timestamp;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.web.multipart.MultipartFile;

class HomeControllerIntegrationTest extends IntegrationTestBase {

  private static final ZoneId BUB_DAY_ZONE = ZoneId.of("Asia/Manila");

  @Autowired private MockMvc mockMvc;
  @Autowired private BubEventRepository bubEvents;
  @Autowired private HomeDailyMomentRepository moments;
  @Autowired private HomeMoodRepository moods;
  @Autowired private TetherConnectionRepository connections;
  @Autowired private TetherInvitationRepository invitations;
  @Autowired private UserRepository users;
  @Autowired private HomeMomentExpiryCleanupService expiryCleanup;
  @Autowired private JdbcTemplate jdbc;

  @BeforeEach
  void setUp() {
    bubEvents.deleteAll();
    moments.deleteAll();
    moods.deleteAll();
    connections.deleteAll();
    invitations.deleteAll();
    users.deleteAll();
    StorageTestConfig.deletedObjectPaths.clear();
    StorageTestConfig.uploadCounter.set(0);
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
        .andExpect(jsonPath("$.latestBub.copy").value("Tether to send bub"))
        .andExpect(jsonPath("$.latestBub.viewerLastSentAt").value(nullValue()))
        .andExpect(jsonPath("$.latestBub.partnerLastSentAt").value(nullValue()))
        .andExpect(jsonPath("$.latestBub.streakDays").value(0))
        .andExpect(jsonPath("$.mood.copy").value("How are you feeling?"))
        .andExpect(jsonPath("$.mood.mood").value(nullValue()));
  }

  @Test
  void dashboardForTetheredUserReturnsPartnerCardData() throws Exception {
    User alice = users.save(user("alice", "alice@example.com", "Alice"));
    User bob = users.save(user("bob", "bob@example.com", "Bob"));
    connections.save(TetherConnection.builder().userOne(alice).userTwo(bob).active(true).build());
    moods.save(HomeMood.builder().user(alice).mood("calm").build());
    moods.save(HomeMood.builder().user(bob).mood("cozy").build());

    mockMvc
        .perform(get("/api/v1/home/dashboard").with(currentUser("alice")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.tether.hasActiveTether").value(true))
        .andExpect(jsonPath("$.tether.partnerUserId").value(bob.getId().toString()))
        .andExpect(jsonPath("$.tether.partnerDisplayName").value("Bob"))
        .andExpect(jsonPath("$.tether.viewerMood").value("calm"))
        .andExpect(jsonPath("$.tether.partnerMood").value("cozy"))
        .andExpect(jsonPath("$.tether.tetheredSince").exists())
        .andExpect(jsonPath("$.latestBub.hasActivity").value(false))
        .andExpect(jsonPath("$.latestBub.copy").value("Send your first Bub"))
        .andExpect(jsonPath("$.latestBub.viewerLastSentAt").value(nullValue()))
        .andExpect(jsonPath("$.latestBub.partnerLastSentAt").value(nullValue()))
        .andExpect(jsonPath("$.latestBub.streakDays").value(0))
        .andExpect(jsonPath("$.mood.copy").value("How are you feeling?"))
        .andExpect(jsonPath("$.mood.mood").value("calm"));
  }

  @Test
  void dashboardIncludesLatestDirectionalBubActivity() throws Exception {
    User alice = users.save(user("alice", "alice@example.com", "Alice"));
    User bob = users.save(user("bob", "bob@example.com", "Bob"));
    TetherConnection connection =
        connections.save(
            TetherConnection.builder().userOne(alice).userTwo(bob).active(true).build());
    bubEvents.save(
        BubEvent.builder()
            .tetherConnection(connection)
            .senderUser(alice)
            .receiverUser(bob)
            .build());
    bubEvents.save(
        BubEvent.builder()
            .tetherConnection(connection)
            .senderUser(bob)
            .receiverUser(alice)
            .build());

    mockMvc
        .perform(get("/api/v1/home/dashboard").with(currentUser("alice")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.latestBub.hasActivity").value(true))
        .andExpect(jsonPath("$.latestBub.viewerLastSentAt").exists())
        .andExpect(jsonPath("$.latestBub.partnerLastSentAt").exists())
        .andExpect(jsonPath("$.latestBub.viewerLastSentCopy").value("You Bubbed them"))
        .andExpect(jsonPath("$.latestBub.partnerLastSentCopy").value("They Bubbed you"))
        .andExpect(jsonPath("$.latestBub.streakDays").value(1));
  }

  @Test
  void dashboardIncludesCurrentBubStreak() throws Exception {
    User alice = users.save(user("alice", "alice@example.com", "Alice"));
    User bob = users.save(user("bob", "bob@example.com", "Bob"));
    TetherConnection connection =
        connections.save(
            TetherConnection.builder().userOne(alice).userTwo(bob).active(true).build());
    Instant noon = todayAtNoon();
    saveBubEvent(connection, alice, bob, noon);
    saveBubEvent(connection, bob, alice, noon.minus(Duration.ofHours(1)));
    saveBubEvent(connection, alice, bob, noon.minus(Duration.ofDays(1)));
    saveBubEvent(connection, bob, alice, noon.minus(Duration.ofDays(1)).minus(Duration.ofHours(1)));
    saveBubEvent(connection, alice, bob, noon.minus(Duration.ofDays(3)));
    saveBubEvent(connection, bob, alice, noon.minus(Duration.ofDays(3)).minus(Duration.ofHours(1)));

    mockMvc
        .perform(get("/api/v1/home/dashboard").with(currentUser("alice")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.latestBub.hasActivity").value(true))
        .andExpect(jsonPath("$.latestBub.streakDays").value(2));
  }

  @Test
  void dashboardKeepsYesterdayBubStreakWhileTodayIsIncomplete() throws Exception {
    User alice = users.save(user("alice", "alice@example.com", "Alice"));
    User bob = users.save(user("bob", "bob@example.com", "Bob"));
    TetherConnection connection =
        connections.save(
            TetherConnection.builder().userOne(alice).userTwo(bob).active(true).build());
    LocalDate yesterday = LocalDate.now(BUB_DAY_ZONE).minusDays(1);
    saveBubEvent(connection, alice, bob, localDayAtNoon(yesterday));
    saveBubEvent(connection, bob, alice, localDayAtNoon(yesterday).plus(Duration.ofMinutes(5)));

    mockMvc
        .perform(get("/api/v1/home/dashboard").with(currentUser("alice")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.latestBub.hasActivity").value(true))
        .andExpect(jsonPath("$.latestBub.streakDays").value(1));
  }

  @Test
  void dashboardCountsConsecutiveMutualBubDays() throws Exception {
    User alice = users.save(user("alice", "alice@example.com", "Alice"));
    User bob = users.save(user("bob", "bob@example.com", "Bob"));
    TetherConnection connection =
        connections.save(
            TetherConnection.builder().userOne(alice).userTwo(bob).active(true).build());
    LocalDate today = LocalDate.now(BUB_DAY_ZONE);
    saveBubEvent(connection, alice, bob, localDayAtNoon(today));
    saveBubEvent(connection, bob, alice, localDayAtNoon(today).plus(Duration.ofMinutes(5)));
    saveBubEvent(connection, alice, bob, localDayAtNoon(today.minusDays(1)));
    saveBubEvent(connection, bob, alice, localDayAtNoon(today.minusDays(1)));
    saveBubEvent(connection, alice, bob, localDayAtNoon(today.minusDays(2)));
    saveBubEvent(connection, bob, alice, localDayAtNoon(today.minusDays(2)));
    saveBubEvent(connection, alice, bob, localDayAtNoon(today.minusDays(4)));
    saveBubEvent(connection, bob, alice, localDayAtNoon(today.minusDays(4)));

    mockMvc
        .perform(get("/api/v1/home/dashboard").with(currentUser("alice")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.latestBub.hasActivity").value(true))
        .andExpect(jsonPath("$.latestBub.streakDays").value(3));
  }

  @Test
  void dashboardDoesNotStartBubStreakFromOneSidedBubActivity() throws Exception {
    User alice = users.save(user("alice", "alice@example.com", "Alice"));
    User bob = users.save(user("bob", "bob@example.com", "Bob"));
    TetherConnection connection =
        connections.save(
            TetherConnection.builder().userOne(alice).userTwo(bob).active(true).build());
    saveBubEvent(connection, alice, bob, todayAtNoon());

    mockMvc
        .perform(get("/api/v1/home/dashboard").with(currentUser("alice")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.latestBub.hasActivity").value(true))
        .andExpect(jsonPath("$.latestBub.streakDays").value(0));
  }

  @Test
  void dashboardEndsBubStreakWhenPartnerLastBubWasFortySevenHoursAgo() throws Exception {
    User alice = users.save(user("alice", "alice@example.com", "Alice"));
    User bob = users.save(user("bob", "bob@example.com", "Bob"));
    TetherConnection connection =
        connections.save(
            TetherConnection.builder().userOne(alice).userTwo(bob).active(true).build());
    LocalDate today = LocalDate.now(BUB_DAY_ZONE);
    saveBubEvent(connection, alice, bob, localDayAtNoon(today));
    saveBubEvent(connection, alice, bob, localDayAtNoon(today.minusDays(1)));
    saveBubEvent(connection, alice, bob, localDayAtNoon(today.minusDays(2)));
    saveBubEvent(connection, bob, alice, localDayAtNoon(today.minusDays(2)));

    mockMvc
        .perform(get("/api/v1/home/dashboard").with(currentUser("alice")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.latestBub.hasActivity").value(true))
        .andExpect(jsonPath("$.latestBub.streakDays").value(0));
  }

  @Test
  void dashboardResetsBubStreakAfterFullyMissedDay() throws Exception {
    User alice = users.save(user("alice", "alice@example.com", "Alice"));
    User bob = users.save(user("bob", "bob@example.com", "Bob"));
    TetherConnection connection =
        connections.save(
            TetherConnection.builder().userOne(alice).userTwo(bob).active(true).build());
    LocalDate today = LocalDate.now(BUB_DAY_ZONE);
    saveBubEvent(connection, alice, bob, localDayAtNoon(today.minusDays(2)));

    mockMvc
        .perform(get("/api/v1/home/dashboard").with(currentUser("alice")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.latestBub.hasActivity").value(true))
        .andExpect(jsonPath("$.latestBub.streakDays").value(0));
  }

  @Test
  void dashboardIgnoresBubActivityFromInactiveTethers() throws Exception {
    User alice = users.save(user("alice", "alice@example.com", "Alice"));
    User bob = users.save(user("bob", "bob@example.com", "Bob"));
    User charlie = users.save(user("charlie", "charlie@example.com", "Charlie"));
    TetherConnection inactiveConnection =
        connections.save(
            TetherConnection.builder().userOne(alice).userTwo(charlie).active(false).build());
    connections.save(TetherConnection.builder().userOne(alice).userTwo(bob).active(true).build());
    bubEvents.save(
        BubEvent.builder()
            .tetherConnection(inactiveConnection)
            .senderUser(alice)
            .receiverUser(charlie)
            .build());

    mockMvc
        .perform(get("/api/v1/home/dashboard").with(currentUser("alice")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.latestBub.hasActivity").value(false))
        .andExpect(jsonPath("$.latestBub.copy").value("Send your first Bub"))
        .andExpect(jsonPath("$.latestBub.viewerLastSentAt").value(nullValue()))
        .andExpect(jsonPath("$.latestBub.partnerLastSentAt").value(nullValue()))
        .andExpect(jsonPath("$.latestBub.streakDays").value(0));
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
        .andExpect(jsonPath("$.viewerPhotoUrl").value("https://cdn.example.com/two.jpg"))
        .andExpect(jsonPath("$.localDate").value(today));

    mockMvc
        .perform(get("/api/v1/home/dashboard").with(currentUser("alice")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.todayMoment.photoUrl").value(nullValue()))
        .andExpect(
            jsonPath("$.todayMoment.viewerPhotoUrl").value("https://cdn.example.com/two.jpg"))
        .andExpect(jsonPath("$.todayMoment.viewerHasPostedToday").value(true));

    mockMvc
        .perform(get("/api/v1/home/dashboard").with(currentUser("bob")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.todayMoment.photoUrl").value("https://cdn.example.com/two.jpg"))
        .andExpect(jsonPath("$.todayMoment.viewerPhotoUrl").value(nullValue()))
        .andExpect(jsonPath("$.todayMoment.partnerCapturedAt").exists())
        .andExpect(jsonPath("$.todayMoment.viewerHasPostedToday").value(false));
  }

  @Test
  void uploadTodayMomentPhotoStoresPhotoThroughBackendStorage() throws Exception {
    User alice = users.save(user("alice", "alice@example.com", "Alice"));
    User bob = users.save(user("bob", "bob@example.com", "Bob"));
    connections.save(TetherConnection.builder().userOne(alice).userTwo(bob).active(true).build());
    String today = LocalDate.now().toString();

    MockMultipartFile photo =
        new MockMultipartFile("file", "moment.jpg", MediaType.IMAGE_JPEG_VALUE, "photo".getBytes());

    mockMvc
        .perform(
            multipart("/api/v1/home/today-moment/photo").file(photo).with(currentUser("alice")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.photoUrl").value("https://cdn.example.com/uploaded-moment-1.jpg"))
        .andExpect(jsonPath("$.localDate").value(today))
        .andExpect(jsonPath("$.viewerHasPostedToday").value(true));

    assertThat(moments.findAll())
        .singleElement()
        .satisfies(
            moment -> {
              assertThat(moment.getStorageObjectPath()).isEqualTo("moments/uploaded-1.jpg");
              assertThat(moment.getExpiresAt()).isNotNull();
            });

    mockMvc
        .perform(get("/api/v1/home/dashboard").with(currentUser("bob")))
        .andExpect(status().isOk())
        .andExpect(
            jsonPath("$.todayMoment.photoUrl")
                .value("https://cdn.example.com/uploaded-moment-1.jpg"))
        .andExpect(jsonPath("$.todayMoment.viewerPhotoUrl").value(nullValue()))
        .andExpect(jsonPath("$.todayMoment.partnerCapturedAt").exists())
        .andExpect(jsonPath("$.todayMoment.viewerHasPostedToday").value(false));
  }

  @Test
  void retakingTodayMomentDeletesPreviousStorageObject() throws Exception {
    User alice = users.save(user("alice", "alice@example.com", "Alice"));
    User bob = users.save(user("bob", "bob@example.com", "Bob"));
    connections.save(TetherConnection.builder().userOne(alice).userTwo(bob).active(true).build());
    MockMultipartFile photo =
        new MockMultipartFile("file", "moment.jpg", MediaType.IMAGE_JPEG_VALUE, "photo".getBytes());

    mockMvc
        .perform(
            multipart("/api/v1/home/today-moment/photo").file(photo).with(currentUser("alice")))
        .andExpect(status().isOk())
        .andExpect(
            jsonPath("$.viewerPhotoUrl").value("https://cdn.example.com/uploaded-moment-1.jpg"));
    mockMvc
        .perform(
            multipart("/api/v1/home/today-moment/photo").file(photo).with(currentUser("alice")))
        .andExpect(status().isOk())
        .andExpect(
            jsonPath("$.viewerPhotoUrl").value("https://cdn.example.com/uploaded-moment-2.jpg"));

    assertThat(StorageTestConfig.deletedObjectPaths).containsExactly("moments/uploaded-1.jpg");
    assertThat(moments.findAll())
        .singleElement()
        .satisfies(
            moment -> {
              assertThat(moment.getPhotoUrl())
                  .isEqualTo("https://cdn.example.com/uploaded-moment-2.jpg");
              assertThat(moment.getStorageObjectPath()).isEqualTo("moments/uploaded-2.jpg");
            });
  }

  @Test
  void cleanupDeletesExpiredMomentStorageObjectAndRow() {
    User alice = users.save(user("alice", "alice@example.com", "Alice"));
    User bob = users.save(user("bob", "bob@example.com", "Bob"));
    TetherConnection connection =
        connections.save(
            TetherConnection.builder().userOne(alice).userTwo(bob).active(true).build());
    moments.save(
        HomeDailyMoment.builder()
            .tetherConnection(connection)
            .createdByUser(alice)
            .localDate(LocalDate.now())
            .photoUrl("https://cdn.example.com/expired.jpg")
            .storageObjectPath("moments/expired.jpg")
            .expiresAt(Instant.now().minusSeconds(1))
            .build());

    expiryCleanup.deleteExpiredMoments();

    assertThat(StorageTestConfig.deletedObjectPaths).containsExactly("moments/expired.jpg");
    assertThat(moments.findAll()).isEmpty();
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
  void cleanupDeletesMoodsOlderThanTwentyFourHours() throws Exception {
    User alice = users.save(user("alice", "alice@example.com", "Alice"));

    mockMvc.perform(putMood("alice", "cozy")).andExpect(status().isOk());
    HomeMood mood = moods.findByUserId(alice.getId()).orElseThrow();
    jdbc.update(
        "update home_moods set updated_at = ? where id = ?",
        Timestamp.from(Instant.now().minus(Duration.ofHours(25))),
        mood.getId());

    expiryCleanup.deleteExpiredMoods();

    assertThat(moods.findByUserId(alice.getId())).isEmpty();
    mockMvc
        .perform(get("/api/v1/home/dashboard").with(currentUser("alice")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.mood.copy").value("How are you feeling?"))
        .andExpect(jsonPath("$.mood.mood").value(nullValue()));
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

  private BubEvent saveBubEvent(
      TetherConnection connection, User sender, User receiver, Instant createdAt) {
    BubEvent event =
        bubEvents.saveAndFlush(
            BubEvent.builder()
                .tetherConnection(connection)
                .senderUser(sender)
                .receiverUser(receiver)
                .build());
    jdbc.update(
        "update bub_events set created_at = ? where id = ?",
        Timestamp.from(createdAt),
        event.getId());
    event.setCreatedAt(createdAt);
    return event;
  }

  private Instant todayAtNoon() {
    return LocalDate.now(BUB_DAY_ZONE).atTime(LocalTime.NOON).atZone(BUB_DAY_ZONE).toInstant();
  }

  private Instant localDayAtNoon(LocalDate localDate) {
    return localDate.atTime(LocalTime.NOON).atZone(BUB_DAY_ZONE).toInstant();
  }

  @TestConfiguration
  static class StorageTestConfig {
    static final AtomicInteger uploadCounter = new AtomicInteger();
    static final List<String> deletedObjectPaths = new ArrayList<>();

    @Bean
    @Primary
    MomentStorageService momentStorageService() {
      return new MomentStorageService() {
        @Override
        public StoredMomentPhoto uploadMoment(
            UUID tetherConnectionId, UUID userId, LocalDate localDate, MultipartFile photo) {
          int uploadNumber = uploadCounter.incrementAndGet();
          return new StoredMomentPhoto(
              "https://cdn.example.com/uploaded-moment-" + uploadNumber + ".jpg",
              "moments/uploaded-" + uploadNumber + ".jpg");
        }

        @Override
        public void deleteMoment(String objectPath) {
          deletedObjectPaths.add(objectPath);
        }
      };
    }
  }
}
