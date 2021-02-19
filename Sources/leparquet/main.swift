import Dispatch
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#else
#error("Unsupported platform")
#endif

LeParquet.main()
exit(EXIT_SUCCESS)
