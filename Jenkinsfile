// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import groovy.json.JsonSlurper

this_stage = "None"
gitCommit = ""
thisSecret = "verysecret"
agentName = ""
this_branch = ""
this_build = ""
os_name = "Focal"
os_version = "20.04"
node_ip = ""
pulp_repo = "testreports"

pipeline {
    agent any

    parameters {
        string(name: 'environment', defaultValue: 'default', description: 'Workspace/environment file to use for deployment')
        string(name: 'version', defaultValue: '', description: 'Version variable to pass to Terraform')
        booleanParam(name: 'autoApprove', defaultValue: false, description: 'Automatically run apply after generating plan?')
    }

    environment {
        JENKINS_CRED = credentials('jenkins-jenkins')
        PULP_CRED = credentials('jenkins-pulp')
        GIT_REPO_NAME = "."
    }

    stages {
        stage('Develop') {
            agent { 
                node { 
                    label 'Dev' 
                } 
            }
            stages {
                stage ('Collect data') {
                    steps {
                        collect_vars("Dev", "Dev")
                    }
                }
                stage ('Switch to build node') {
                    steps {
                        prepare("${this_stage}", "${gitCommit}")
                    }
                }
                stage ('Deploy infra') {
                    stages {
                        stage('Plan') {
                            steps {
                                script {
                                    currentBuild.displayName = params.version
                                }
                                sh "terraform -chdir=${GIT_REPO_NAME} init -input=false"
                                sh "terraform workspace new ${gitCommit}"
                                //sh "terraform -chdir=${GIT_REPO_NAME} plan -input=false -var-file='target.auto.tfvars.json'"

                            }
                        }
                         stage('Apply') {
                             steps {
                                echo "Deploying infrastructure for stage ${this_stage}"
                                //  sh "terraform -chdir=${GIT_REPO_NAME} apply -input=false -auto-approve -var-file='target.auto.tfvars.json'"
                                // node_ip = sh(returnStdout: true, script: "terraform output node_ip").trim()
                             }
                         }
                    }
                }
                stage ('Deploying the system') {
                    steps {
                        echo "OS STIG compliancy configuration for stage ${this_stage}"
                        // startplaybook("${this_stage}","deploy")
                    }
                }
                stage('Smoke test') {
                    steps {
                        script {
                            // sh "oscap-ssh user@${node_ip} 22 xccdf eval --profile xccdf_org.ssgproject.content_profile_stig --report pre-deploy_report.html ./scap-security-guide-0.1.69/ssg-ubuntu2004-ds-1.2.xml"
                            //sh "robot --variable VALID_PASSWORD:${thisSecret} -d  test_results --variable NODE:PS1 --variable STAGE:Dev robot/smoketest.robot"
                            currentBuild.result = 'SUCCESS'
                        }
                    }
                }
                stage ('Cleanup') {
                    stages {
                        stage('Cleanup after myself') {
                            steps {
                                cleanup("Develop", "${gitCommit}")
                            }
                        }
                         stage('Destroy infrastructure') {
                             steps {
                                echo "Destroying infrastructure for stage ${this_stage}"
                                //  sh "terraform -chdir=${GIT_REPO_NAME} destroy -input=false -auto-approve -var-file='../testapp.auto.tfvars.json'"
                             }
                         }
                    }
                }
            }
        }
    }
    post {
        always {
            script {
                if (fileExists('test_results/output.xml')) {
                    step(
                        [
                            $class              : 'RobotPublisher',
                            outputPath          : 'test_results',
                            outputFileName      : 'output.xml',
                            reportFileName      : "${this_stage}-${thisbranch}-${thisbuild}-${gitcommit}-report.html",
                            logFileName         : 'log.html',
                            disableArchiveOutput: true,
                            otherFiles          : "*.png,*.jpg",
                        ]
                    )
                }

            }    
            echo "Archiving artifacts"
            archiveArtifacts artifacts: '**/*', fingerprint: true
            writeFile file: "test_results/${gitCommit}-jenkins_console_output.txt", text: currentBuild.rawBuild.logFile.text
            sh "sed -ri \"s/\\x1b\\[8m.*?\\x1b\\[0m//g\" test_results/${gitCommit}-jenkins_console_output.txt"
            /* clean up our workspace */
            script {
                dir('test_results') {
                    def files = findFiles() 
                    echo "${files}"
                    files.each { f -> 
                        if (f.name != ".gitignore") {
                            sh 'pulp --base-url https://pulp.tooling.' + "${env.DOMAIN_NAME_SL}" + '.' + "${env.DOMAIN_NAME_TL}" + ' --no-verify-ssl --username $PULP_CRED_USR --password $PULP_CRED_PSW file content upload --repository ' + "${pulp_repo}" + ' --file ' + "${f.name}" + ' --relative-path ' + "${gitCommit}" + '/' + "${f.name}"
                        }
                    }
                }
            }
            deleteDir()
        }
        success {
            echo "Build ${env.BUILD_tag}, commit: ${gitCommit} was a success."
            //mail to: 'architect@infraautomator.example.com',
            //subject: "Build ${env.BUILD_tag}, commit: ${gitCommit} was successful.",
            //body: "Build is on branch ${env.JOB_NAME}"
        }
        unsuccessful {
            echo "Build ${env.BUILD_tag}, commit: ${gitCommit} failed."
            //mail to: 'architect@infraautomator.example.com',
            //subject: "Build ${env.BUILD_tag}, commit: ${gitCommit} was successful.",
            //body: "Build is on branch ${env.JOB_NAME}"
        }
        changed {
            echo "${env.JOB_NAME} behaved differently last time..."
        }
    }
}

def collect_vars(stage, my_env) {
    script {
        // Set global variables
        gitCommit = "${env.GIT_COMMIT[0..7]}"
        this_stage= "${stage}"
        this_branch="${env.BRANCH_NAME}"
        this_build="${env.BUILD_tag}"
    }                       
    echo "The commit is on branch ${env.JOB_NAME}, with short ID: ${gitCommit}"
    echo 'Creating Jenkins Agent'
    script {
        thisSecret = startagent("${env.BRANCH_NAME}","${env.BUILD_tag}","${gitCommit}")
    }

    script {
        agentName = "${GIT_REPO_NAME}-${env.BRANCH_NAME}-${gitCommit}"
    }
    echo "The agent for the next phase is: ${agentName}"

    return null
}

def prepare(stage, commit) {
    //echo "Switched to jenkins agent: ${GIT_REPO_NAME}-${env.BRANCH_NAME}-${stage}-${commit}"
    checkout([
        $class: 'GitSCM',
        branches: scm.branches,
        doGenerateSubmoduleConfigurations: true,
        extensions: scm.extensions + [[$class: 'SubmoduleOption', parentCredentials: true]],
        userRemoteConfigs: scm.userRemoteConfigs
    ])
    return null
}

def startagent(branch, build, commit) {
    echo "Create Jenkins build node placeholder for repository: ${GIT_REPO_NAME}, branch: ${branch}, build: ${build} (commit:  ${commit})"
    //sh 'curl -L -s -o /dev/null -u ' + "${JENKINS_CRED}" + ' -H Content-Type:application/x-www-form-urlencoded -X POST -d \'json={"name":+"' + "${GIT_REPO_NAME}" + "-" + "${branch}" + "-" + "${commit}" + '",+"nodeDescription":+"${GIT_REPO_NAME}:+' + "${GIT_REPO_NAME}" + "-" + "${branch}" + "-" + "${commit}" + '",+"numExecutors":+"1",+"remoteFS":+"/home/jenkins",+"labelString":+"' + "${GIT_REPO_NAME}" + "-" + "${branch}" + "-"+ "${commit}" + '",+"mode":+"EXCLUSIVE",+"":+["hudson.slaves.JNLPLauncher",+"hudson.slaves.RetentionStrategy$Always"],+"launcher":+{"stapler-class":+"hudson.slaves.JNLPLauncher",+"$class":+"hudson.slaves.JNLPLauncher",+"workDirSettings":+{"disabled":+false,+"workDirPath":+"",+"internalDir":+"remoting",+"failIfWorkDirIsMissing":+false},+"tunnel":+"",+"vmargs":+""},+"retentionStrategy":+{"stapler-class":+"hudson.slaves.RetentionStrategy$Always",+"$class":+"hudson.slaves.RetentionStrategy$Always"},+"nodeProperties":+{"stapler-class-bag":+"true"},+"type":+"hudson.slaves.DumbSlave"}\' "' + "${env.JENKINS_URL}" + 'computer/doCreateItem?name="' + "${GIT_REPO_NAME}" + "-" + "${branch}" + "-" + "${commit}" + '"&type=hudson.slaves.DumbSlave"'

    //echo 'Retrieve Agent Secret'
    //script {
    //    agentSecret = jenkins.model.Jenkins.getInstance().getComputer("${GIT_REPO_NAME}" + "-" + "${branch}" + "-" + "$commit").getJnlpMac()
    //}
    return null
    //return "${agentSecret}"
}

def stopagent(branch, build, commit) {
    echo "Remove Jenkins build node placeholder for repository: ${GIT_REPO_NAME}, branch: ${branch}, build: ${build} (commit:  ${commit})"
    //sh 'curl -L -s -o /dev/null -u ' + "${JENKINS_CRED}" + ' -H "Content-Type:application/x-www-form-urlencoded" -X POST "' + "${env.JENKINS_URL}" + 'computer/' + "${GIT_REPO_NAME}" + "-" + "${branch}" + "-" + "${commit}" + '/doDelete"'
    
    return null
}

def startplaybook(stage,compartiment) {
    ansiblePlaybook installation: 'ansible', inventory: "./ansible/terraform.py", playbook: "ansible/${stage}.yml", extraVars: ["os_version": "${os_version}", "os_name": "${os_name}"], extras: '-vvvv'

}

def cleanup(env, commit) {
    echo "Switch to jenkins agent: ${env}"

    echo 'Remove Jenkins Agent'
    stopagent("${this_branch}","${this_build}","${commit}")
    sh "terraform workspace select default"
    sh "terraform workspace delete ${gitCommit}"
    return null
}
