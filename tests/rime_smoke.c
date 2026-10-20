#include <assert.h>
#include <stdio.h>
#include <string.h>
#include <rime_api.h>

int main(int argc, char **argv) {
  assert(argc == 3);
  RimeApi *api = rime_get_api();
  RIME_STRUCT(RimeTraits, traits);
  traits.shared_data_dir = argv[1];
  traits.user_data_dir = argv[2];
  traits.log_dir = argv[2];
  traits.app_name = "rime.trifecta-smoke";
  api->setup(&traits);
  api->initialize(NULL);
  if (api->start_maintenance(True)) api->join_maintenance_thread();
  assert(api->find_module("lua"));
  RimeSessionId session = api->create_session();
  assert(session && api->select_schema(session, "luna_pinyin"));
  assert(api->simulate_key_sequence(session, "nihao"));
  RIME_STRUCT(RimeContext, ctx);
  assert(api->get_context(session, &ctx));
  assert(ctx.menu.num_candidates > 0);
  printf("nihao candidate: %s\n", ctx.menu.candidates[0].text);
  api->free_context(&ctx);
  assert(api->simulate_key_sequence(session, "{Caps_Lock}"));
  RIME_STRUCT(RimeCommit, commit);
  assert(api->get_commit(session, &commit));
  assert(strcmp(commit.text, "nihao") == 0);
  api->free_commit(&commit);
  api->clear_composition(session);
  api->set_option(session, "ascii_mode", False);
  api->set_option(session, "full_shape", False);
  assert(api->simulate_key_sequence(session, "/"));
  assert(api->get_context(session, &ctx));
  assert(ctx.menu.num_candidates > 0);
  assert(strcmp(ctx.menu.candidates[0].text, "/") == 0);
  api->free_context(&ctx);
  api->clear_composition(session);
  api->destroy_session(session);
  session = api->create_session();
  assert(api->select_schema(session, "luna_pinyin"));
  assert(api->simulate_key_sequence(session, "bss-service"));
  assert(api->get_context(session, &ctx));
  assert(strcmp(ctx.composition.preedit, "bss-service") == 0);
  api->free_context(&ctx);
  assert(api->simulate_key_sequence(session, "{Return}"));
  assert(api->get_commit(session, &commit));
  assert(strcmp(commit.text, "bss-service") == 0);
  api->free_commit(&commit);
  assert(api->simulate_key_sequence(session, "ni{Page_Down}"));
  assert(api->get_context(session, &ctx));
  assert(ctx.menu.page_no == 1);
  api->free_context(&ctx);
  assert(api->simulate_key_sequence(session, "-"));
  assert(api->get_context(session, &ctx));
  assert(ctx.menu.page_no == 0);
  api->free_context(&ctx);
  api->destroy_session(session);
  api->finalize();
  puts("Rime runtime: candidates, Caps Lock, slash, hyphen and Lua passed");
}
