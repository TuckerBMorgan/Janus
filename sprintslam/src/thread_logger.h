

//
class ThreadLoggerSingleton {
    static ThreadLoggerSingleton* Instance();
    void printf(int threadId, char* log);

	private:
	   ThreadLoggerSingleton(){};  // Private so that it can  not be called
	   ThreadLoggerSingleton(ThreadLoggerSingleton const&){};             // copy constructor is private
	   ThreadLoggerSingleton& operator=(Logger const&){};  // assignment operator is private
	   static ThreadLoggerSingleton* m_pInstance;
}