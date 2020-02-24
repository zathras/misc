plugins {
    java
    kotlin("jvm") version "1.3.61"
}

group = "org.example"
version = "1.0-SNAPSHOT"

repositories {
    jcenter()
    maven {
        url = uri("http://maven.jovial.com")  
        // Redirects to https://dl.bintray.com/zathras/maven/

        // For github pacakges:
        // url = uri("https://maven.pkg.github.com/zathras/db9010")
        // credentials {
        //     username = "zathras"
        //     password = "mumble"
        // }
        //
        // Strangely, Github Packages requires credentials for a public
        // repository.  That's inconvenient, especially since Github prevents
        // one from publishing a credential -- even one that just allows read
        // access on packages.
    }
}

dependencies {
    implementation(kotlin("stdlib-jdk8"))
    implementation("com.h2database", "h2", "1.4.200")
    implementation("com.jovial", "db9010", "0.2.0")
    testCompile("junit", "junit", "4.12")
}

configure<JavaPluginConvention> {
    sourceCompatibility = JavaVersion.VERSION_1_8
}
tasks {
    compileKotlin {
        kotlinOptions.jvmTarget = "1.8"
    }
    compileTestKotlin {
        kotlinOptions.jvmTarget = "1.8"
    }
}
