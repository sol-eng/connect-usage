
client <- connectapi::connect()

pins::board_register_rsconnect(server = Sys.getenv("CONNECT_SERVER"),
                         key = Sys.getenv("CONNECT_API_KEY"))


all_content <- connectapi::get_content(client, limit = Inf)

pins::pin(all_content, "rsc_content_list", board = 'rsconnect')
