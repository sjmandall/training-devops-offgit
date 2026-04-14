Day 21 Runbook

Topic
Ansible idempotent workstation configuration.

Objective
- Write Ansible role or playbook to configure Ubuntu workstation.
- Configure packages, Docker, kubectl, Helm, Jenkins prerequisites.
- Ensure idempotent - second run shows no changes.
- Support check mode where possible.

Evidence Required
1. infra/ansible/ committed to GitHub.
2. Second run shows no changes (changed=0).
3. Basic --check run output captured in docs/.

Environment
- Host: Windows with WSL2 Ubuntu 24.04
- User: webadmin
- Project root: ~/project
- Ansible folder: ~/project/infra/ansible
- Repo: https://github.com/sjmandall/training-devops-offgit.git
- Ansible version: 2.16.3

Prerequisites
- Ansible installed: ansible --version
- sudo access: webadmin ALL=(ALL) NOPASSWD: ALL in /etc/sudoers.d/webadmin
- Git configured: git config --list
- Project repo cloned at ~/project

Project Structure

infra/ansible/
    inventory.ini
    playbook.yaml
    roles/
        workstation/
            tasks/
                main.yaml
                packages.yaml
                docker.yaml
                kubectl.yaml
                helm.yaml
                jenkins.yaml
            handlers/
                main.yaml
            defaults/
                main.yaml
            meta/
                main.yaml

docs/
    day21-runbook.txt
    day21-ansible-check.txt
    day21-ansible-first-run.txt
    day21-ansible-second-run.txt

Step 1: Install Ansible

  sudo apt update
  sudo apt install ansible -y
  ansible --version

Expected:
  ansible [core 2.16.x]


Step 3: Create folder structure

  mkdir -p ~/project/infra/ansible/roles/workstation/{tasks,handlers,defaults,meta}
  cd ~/project/infra/ansible

Verify:
  find ~/project/infra/ansible -type d

Step 4: Create inventory.ini

File: ~/project/infra/ansible/inventory.ini

Content:
  [workstation]
  localhost ansible_connection=local ansible_user=webadmin


Step 5: Create defaults/main.yaml (variables)

File: ~/project/infra/ansible/roles/workstation/defaults/main.yaml

Variables defined:
  common_packages  = list of base tools (curl, wget, git, make etc)
  java_package     = openjdk-21-jdk (required for Jenkins)
  docker_packages  = docker.io and docker-compose
  kubectl_version  = v1.29.0
  jenkins_key_path = /etc/apt/keyrings/jenkins-keyring.asc


Step 6: Create tasks/packages.yaml

File: ~/project/infra/ansible/roles/workstation/tasks/packages.yaml

Tasks:
  1. Update apt cache (cache_valid_time: 3600 for idempotency)
  2. Install common packages (state: present = idempotent)
  3. Install Java openjdk-21-jdk
  4. Verify Java version (changed_when: false)
  5. Show Java version (when: java_version.rc == 0)

Key concepts:
  state: present = install only if missing (idempotent)
  cache_valid_time: 3600 = skip apt update if done within 1 hour
  changed_when: false = verification tasks never count as changed
  ignore_errors: yes = continue if verification fails
  java -version outputs to stderr not stdout (Java design)

Step 7: Create tasks/docker.yaml

File: ~/project/infra/ansible/roles/workstation/tasks/docker.yaml

Tasks:
  1. Install Docker packages (notify: Restart Docker)
  2. Add webadmin to docker group (append: yes)
  3. Enable and start Docker service (systemd)
  4. Verify Docker version
  5. Show Docker version

Key concepts:
  notify: Restart Docker = triggers handler only if Docker changed
  append: yes = add to group without removing existing groups
  systemd enabled: yes = auto-start on boot
  systemd state: started = ensure running now (idempotent)
  docker --version outputs to stdout

Step 8: Create tasks/kubectl.yaml

File: ~/project/infra/ansible/roles/workstation/tasks/kubectl.yaml

Tasks:
  1. Check if kubectl exists (stat module)
  2. Download kubectl binary (when: not kubectl_binary.stat.exists)
  3. Verify kubectl version (changed_when: false)
  4. Show kubectl version

Key concepts:
  stat module = check if file exists, saves to register variable
  register: kubectl_binary = saves stat result
  kubectl_binary.stat.exists = true or false
  when: not kubectl_binary.stat.exists = download only if missing
  mode: 0755 = make binary executable
  --client flag = check client version without connecting to cluster
  Do NOT use --short flag (removed in newer kubectl versions)

Step 9: Create tasks/helm.yaml

File: ~/project/infra/ansible/roles/workstation/tasks/helm.yaml

Tasks:
  1. Check if Helm exists (stat module)
  2. Download Helm install script (get_url, mode: 0700)
  3. Run Helm install script (when: not helm_binary.stat.exists)
  4. Verify Helm version
  5. Show Helm version

Key concepts:
  Same check-first pattern as kubectl.
  Helm uses an installer script not a direct binary download.
  mode: 0700 = owner can execute, others cannot.
  Both download and install tasks have when: not helm_binary.stat.exists.

Step 10: Create tasks/jenkins.yaml

File: ~/project/infra/ansible/roles/workstation/tasks/jenkins.yaml

Tasks:
  1. Check if Jenkins key exists (stat module)
  2. Add Jenkins GPG key (shell module with pipe)
  3. Add Jenkins apt repository (apt_repository module)
  4. Update apt cache after adding repo
  5. Install Jenkins (notify: Restart Jenkins)
  6. Enable and start Jenkins service
  7. Verify Jenkins is running
  8. Show Jenkins status

Key concepts:
  shell module used for GPG key task because it needs pipe (|).
  command module cannot handle pipes.
  apt_repository state: present = idempotent repo addition.
  jenkins_key_path must match existing installation path.
  On this system correct path is /etc/apt/keyrings/jenkins-keyring.asc.

Important jenkins.list fix:
  Jenkins was manually installed before Ansible.
  Two conflicting repo entries appeared in /etc/apt/sources.list.d/jenkins.list.
  Fixed by removing the wrong entry:
    sudo sed -i '/usr\/share\/keyrings/d' /etc/apt/sources.list.d/jenkins.list
  Verified with:
    cat /etc/apt/sources.list.d/jenkins.list
  Only one line should remain:
    deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/

Step 11: Create tasks/main.yaml

File: ~/project/infra/ansible/roles/workstation/tasks/main.yaml

Content:
  include_tasks: packages.yaml
  include_tasks: docker.yaml
  include_tasks: kubectl.yaml
  include_tasks: helm.yaml
  include_tasks: jenkins.yaml

Why:
  Entry point Ansible reads when role is called.
  Controls order of execution.
  packages.yaml must run first (Java needed by Jenkins).
  jenkins.yaml must run last (needs Java from packages.yaml).

Step 12: Create handlers/main.yaml

File: ~/project/infra/ansible/roles/workstation/handlers/main.yaml

Handlers:
  Restart Docker  = systemd state: restarted
  Restart Jenkins = systemd state: restarted

Why handlers:
  Only run when notified by a task.
  Run ONCE at end of playbook even if notified multiple times.
  state: restarted is correct (not restart - that is invalid).
  If Docker already installed on second run, handler never fires.

Step 13: Create meta/main.yaml

File: ~/project/infra/ansible/roles/workstation/meta/main.yaml

Content:
  role_name: workstation
  author: webadmin
  min_ansible_version: "2.9"
  platforms: Ubuntu focal and jammy
  dependencies: []

Why:
  Documents role metadata.
  dependencies: [] means role is standalone, no other roles needed.
  Pure documentation, does not affect execution.

Step 14: Create playbook.yaml

File: ~/project/infra/ansible/playbook.yaml

Sections:
  hosts: workstation
  become: yes
  gather_facts: yes
  pre_tasks: show host info, update apt cache
  roles: - workstation
  post_tasks: verify all tools, print summary

Key variables in summary:
  java_final.stderr  = Java outputs version to stderr
  docker_final.stdout = Docker outputs to stdout
  kubectl_final.stdout = kubectl outputs to stdout
  helm_final.stdout  = Helm outputs to stdout
  jenkins_final.stdout = systemctl is-active outputs to stdout
  | default('not found') = safe fallback if variable empty

Step 15: Run syntax check

  cd ~/project/infra/ansible
  ansible-playbook playbook.yaml -i inventory.ini --syntax-check

Expected:
  playbook: playbook.yaml

Step 16: Run check mode (evidence 3)

  ansible-playbook playbook.yaml -i inventory.ini --check \
    2>&1 | tee ~/project/docs/day21-ansible-check.txt


Step 17: First run (evidence 1 partial)

  ansible-playbook playbook.yaml -i inventory.ini \
    2>&1 | tee ~/project/docs/day21-ansible-first-run.txt

Expected PLAY RECAP:
  localhost : ok=25 changed=8 unreachable=0 failed=0

Step 18: Second run (evidence 2)

  ansible-playbook playbook.yaml -i inventory.ini \
    2>&1 | tee ~/project/docs/day21-ansible-second-run.txt

Expected PLAY RECAP:
  localhost : ok=25 changed=0 unreachable=0 failed=0

changed=0 proves idempotency which is the core Day 21 requirement.

Step 19: Commit all files

  cd ~/project

  git add infra/ansible/
  git add docs/day21-runbook.txt
  git add docs/day21-ansible-check.txt
  git add docs/day21-ansible-first-run.txt
  git add docs/day21-ansible-second-run.txt

  git status

  git commit -m "feat: day21 Ansible idempotent workstation role"
  git push origin main

Day 21 Outcomes Checklist

  Requirement                          How satisfied
  infra/ansible/ committed             All role files committed to GitHub
  Packages configured                  packages.yaml installs curl wget git java
  Docker configured                    docker.yaml installs and starts Docker
  kubectl configured                   kubectl.yaml downloads binary
  Helm configured                      helm.yaml runs install script
  Jenkins prerequisites configured     jenkins.yaml installs Jenkins
  Idempotent                           Second run shows changed=0
  Check mode supported                 --check run captured in docs
  Second run no changes                day21-ansible-second-run.txt shows changed=0
  --check output captured              day21-ansible-check.txt in docs

