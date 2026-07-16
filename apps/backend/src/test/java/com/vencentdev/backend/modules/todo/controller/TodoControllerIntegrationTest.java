package com.vencentdev.backend.modules.todo.controller;

import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.nullValue;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.vencentdev.backend.IntegrationTestBase;
import com.vencentdev.backend.modules.todo.entity.Todo;
import com.vencentdev.backend.modules.todo.enums.TodoStatus;
import com.vencentdev.backend.modules.todo.repository.TodoRepository;
import com.vencentdev.backend.modules.user.entity.User;
import com.vencentdev.backend.modules.user.enums.KycStatus;
import com.vencentdev.backend.modules.user.enums.Role;
import com.vencentdev.backend.modules.user.enums.UserType;
import com.vencentdev.backend.modules.user.repository.UserRepository;
import java.time.LocalDate;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import tools.jackson.databind.ObjectMapper;

class TodoControllerIntegrationTest extends IntegrationTestBase {

  @Autowired private MockMvc mockMvc;
  @Autowired private ObjectMapper objectMapper;
  @Autowired private TodoRepository todoRepository;
  @Autowired private UserRepository userRepository;

  @BeforeEach
  void setUp() {
    todoRepository.deleteAll();
    userRepository.deleteAll();
  }

  @Test
  void crudHappyPathForOneUser() throws Exception {
    UUID id = createTodoAs("user-a", "First todo", "2027-01-15");

    mockMvc
        .perform(get("/api/v1/todos").with(currentUser("user-a")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.content", hasSize(1)))
        .andExpect(jsonPath("$.content[0].id").value(id.toString()));

    mockMvc
        .perform(get("/api/v1/todos/{id}", id).with(currentUser("user-a")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.title").value("First todo"));

    mockMvc
        .perform(
            patch("/api/v1/todos/{id}", id)
                .with(currentUser("user-a"))
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"title\":\"Updated todo\",\"status\":\"DONE\"}"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.title").value("Updated todo"))
        .andExpect(jsonPath("$.status").value("DONE"));

    mockMvc
        .perform(delete("/api/v1/todos/{id}", id).with(currentUser("user-a")))
        .andExpect(status().isNoContent());

    assertFalse(todoRepository.existsById(id));
  }

  @Test
  void crossUserIsolationPreventsListReadPatchAndDelete() throws Exception {
    UUID todoId = createTodoAs("user-a", "Private todo", "2027-01-15");

    mockMvc
        .perform(get("/api/v1/todos").with(currentUser("user-b")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.content", hasSize(0)));

    mockMvc
        .perform(get("/api/v1/todos/{id}", todoId).with(currentUser("user-b")))
        .andExpect(status().isNotFound());

    mockMvc
        .perform(
            patch("/api/v1/todos/{id}", todoId)
                .with(currentUser("user-b"))
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"title\":\"hacked\"}"))
        .andExpect(status().isForbidden());

    mockMvc
        .perform(delete("/api/v1/todos/{id}", todoId).with(currentUser("user-b")))
        .andExpect(status().isForbidden());
  }

  @Test
  void forgedOwnerIdInBodyIsIgnored() throws Exception {
    User userA = userRepository.save(user("user-a"));
    User userB = userRepository.save(user("user-b"));

    MvcResult result =
        mockMvc
            .perform(
                post("/api/v1/todos")
                    .with(currentUser("user-a"))
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(
                        """
                        {
                          "ownerId": "%s",
                          "title": "Forged owner",
                          "description": "ignored",
                          "status": "TODO",
                          "dueDate": "2027-01-15"
                        }
                        """
                            .formatted(userB.getId())))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.title").value("Forged owner"))
            .andReturn();

    UUID todoId = responseId(result);
    Todo todo = todoRepository.findById(todoId).orElseThrow();
    assertEquals(userA.getId(), todo.getOwnerId());
  }

  @Test
  void patchJsonNullableSemanticsForDueDate() throws Exception {
    UUID id = createTodoAs("user-a", "Patch todo", "2027-01-15");

    mockMvc
        .perform(
            patch("/api/v1/todos/{id}", id)
                .with(currentUser("user-a"))
                .contentType(MediaType.APPLICATION_JSON)
                .content("{}"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.dueDate").value("2027-01-15"));

    mockMvc
        .perform(
            patch("/api/v1/todos/{id}", id)
                .with(currentUser("user-a"))
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"dueDate\":null}"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.dueDate").value(nullValue()));

    Todo afterClear = todoRepository.findById(id).orElseThrow();
    assertEquals(null, afterClear.getDueDate());

    mockMvc
        .perform(
            patch("/api/v1/todos/{id}", id)
                .with(currentUser("user-a"))
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"title\":\"Missing due date\"}"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.dueDate").value(nullValue()));

    mockMvc
        .perform(
            patch("/api/v1/todos/{id}", id)
                .with(currentUser("user-a"))
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"dueDate\":\"2027-01-15\"}"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.dueDate").value("2027-01-15"));

    Todo afterSet = todoRepository.findById(id).orElseThrow();
    assertEquals(LocalDate.of(2027, 1, 15), afterSet.getDueDate());
  }

  @Test
  void paginationReturnsRequestedPageShape() throws Exception {
    User owner = userRepository.save(user("user-a"));
    for (int i = 0; i < 25; i++) {
      todoRepository.save(
          Todo.builder()
              .ownerId(owner.getId())
              .title("Todo " + i)
              .description("Seeded")
              .status(TodoStatus.TODO)
              .dueDate(LocalDate.of(2027, 1, 1).plusDays(i))
              .build());
    }

    mockMvc
        .perform(get("/api/v1/todos?page=0&size=10").with(currentUser("user-a")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.content", hasSize(10)))
        .andExpect(jsonPath("$.page").value(0))
        .andExpect(jsonPath("$.size").value(10))
        .andExpect(jsonPath("$.totalElements").value(25))
        .andExpect(jsonPath("$.totalPages").value(3));
  }

  private UUID createTodoAs(String subject, String title, String dueDate) throws Exception {
    userRepository.save(user(subject));
    MvcResult result =
        mockMvc
            .perform(
                post("/api/v1/todos")
                    .with(currentUser(subject))
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(
                        """
                        {
                          "title": "%s",
                          "description": "Created in test",
                          "status": "TODO",
                          "dueDate": "%s"
                        }
                        """
                            .formatted(title, dueDate)))
            .andExpect(status().isCreated())
            .andReturn();
    return responseId(result);
  }

  private UUID responseId(MvcResult result) throws Exception {
    String id = objectMapper.readTree(result.getResponse().getContentAsString()).get("id").asText();
    assertNotNull(id);
    return UUID.fromString(id);
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

  private User user(String externalId) {
    return User.builder()
        .externalId(externalId)
        .email(externalId + "@example.com")
        .displayName(externalId)
        .role(Role.USER)
        .userType(UserType.INDIVIDUAL)
        .kycStatus(KycStatus.NONE)
        .build();
  }
}
