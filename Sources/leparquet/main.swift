import Dispatch
#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#else
    #error("Unsupported platform")
#endif

// @main

LeParquet.main()

// DispatchQueue.global().async {
// DispatchQueue.main.async {
//    layout.calculate()
// }
// dispatchMain()

exit(EXIT_SUCCESS)
