plugins {
    java
    kotlin("jvm") version "1.3.61"
}

group = "org.example"
version = "1.0-SNAPSHOT"

repositories {
    mavenCentral()
    maven {
        url = uri("https://maven.pkg.github.com/zathras/db9010")
        credentials {
            username = "zathras"
            password = "848e249a25d6c3da4b68287ba619aed81b6867a7"
            // It's a little weird that Github Packages requires a token
            // to access a maven repo that's part of a *public* github
            // repository.  Since all of my github repos on this account
            // are public, I don't think there's any harm in publishing
            // this token, which only has "read:packages" permission.
        }
    }
}

dependencies {
    implementation(kotlin("stdlib-jdk8"))
    implementation("com.h2database", "h2", "1.4.200")
    implementation("com.jovial.db9010", "db9010", "0.1.0")
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
