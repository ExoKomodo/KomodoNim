import komodo/lib/raylib

func logInfo*(message: string) =
    TraceLog(LOG_INFO, message)
