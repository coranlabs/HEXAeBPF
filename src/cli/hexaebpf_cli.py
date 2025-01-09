import os
from rich.console import Console
from rich.prompt import Prompt, IntPrompt
from rich.table import Table
from rich.progress import Progress
from prompt_toolkit.completion import WordCompleter
import time
import subprocess
from rich.panel import Panel
from rich.align import Align
from rich.progress import Progress
from rich.box import HEAVY  # Import the desired box style
from rich.progress import Progress, BarColumn, TextColumn, TimeElapsedColumn
import sys


# Initialize global variables
AMF_IP = None

# Initialize console for styled output
console = Console()

# Example Control Plane and User Plane options
control_planes = ["SD Core", "Free5GC", "Open5GS", "OAI"]
user_planes = ["edgecomllc/eUPF", "OAI-UPF-eBPF"]
ran_simulators_common = ["UERANSIM"]
ran_simulators_oai = ["OAI-RFSimulator"]

# Operator commands for undeployment
undeploy_commands = {
    "SD Core-edgecomllc/eUPF": """
kubectl delete -f ~/HEXAeBPF/src/operators/HEXAeBPF_Operator/HEXAeBPF-sdcore-eupf-operator/hexa-sdcore-eupf-cp-operator/config/samples/sdcore_v1_hexacp.yaml -n hexa
cd ~/HEXAeBPF/src/operators/HEXAeBPF_Operator/HEXAeBPF-sdcore-eupf-operator/hexa-sdcore-eupf-cp-operator && make undeploy
""",
    "SD Core-OAI-UPF-eBPF": """
kubectl delete -f ~/HEXAeBPF/src/operators/HEXAeBPF_Operator/HEXAeBPF-sdcore-eupf-operator/hexa-sdcore-eupf-up-operator/config/samples/eupf_v1_hexaup.yaml -n hexa
cd ~/HEXAeBPF/src/operators/HEXAeBPF_Operator/HEXAeBPF-sdcore-eupf-operator/hexa-sdcore-eupf-up-operator && make undeploy
""",
    "OAI-OAI-UPF-eBPF": """
kubectl delete -f ~/HEXAeBPF/src/operators/HEXAeBPF_Operator/HEXAeBPF-oai-ebpf-operator/hexa-oai-ebpf-operator/config/samples/oai.ebpf_v1_hexaoai.yaml -n hexa
cd ~/HEXAeBPF/src/operators/HEXAeBPF_Operator/HEXAeBPF-oai-ebpf-operator/hexa-oai-ebpf-operator && make undeploy
""",
    "OAI-RFSimulator": """
kubectl delete -f ~/HEXAeBPF/src/operators/HEXAeBPF_Operator/HEXAeBPF-oai-rfsimulator-operator/hexa-oai-nr-ue-operator/config/samples/oai.nr.ue_v1_hexaoainrue.yaml -n hexa
cd ~/HEXAeBPF/src/operators/HEXAeBPF_Operator/HEXAeBPF-oai-rfsimulator-operator/hexa-oai-nr-ue-operator && make undeploy
kubectl delete -f ~/HEXAeBPF/src/operators/HEXAeBPF_Operator/HEXAeBPF-oai-rfsimulator-operator/hexa-oai-gnb-operator/config/samples/oai.gnb_v1_hexaoaignb.yaml -n hexa
cd ~/HEXAeBPF/src/operators/HEXAeBPF_Operator/HEXAeBPF-oai-rfsimulator-operator/hexa-oai-gnb-operator && make undeploy
""",
    "UERANSIM": """
kubectl delete -f ~/HEXAeBPF/src/operators/HEXAeBPF_Operator/HEXAeBPF-ueransim-operator/hexa-ueransim-operator/config/samples/open5gs_v1_hexaueransim.yaml -n hexa
kubectl delete -f ~/HEXAeBPF/src/operators/HEXAeBPF_Operator/HEXAeBPF-ueransim-operator/hexa-ueransim-operator/config/samples/free5gc_v1_hexaueransim.yaml -n hexa
kubectl delete -f ~/HEXAeBPF/src/operators/HEXAeBPF_Operator/HEXAeBPF-ueransim-operator/hexa-ueransim-operator/config/samples/sdcore_v1_hexaueransim.yaml -n hexa
cd ~/HEXAeBPF/src/operators/HEXAeBPF_Operator/HEXAeBPF-ueransim-operator/hexa-ueransim-operator && make undeploy
""",
    "Open5GS-edgecomllc/eUPF": """
kubectl delete -f ~/HEXAeBPF/src/operators/HEXAeBPF_Operator/HEXAeBPF-open5gs-eupf-operator/hexa-open5gs-eupf-cp-operator/config/samples/open5gs_v1_hexacp.yaml -n hexa
cd ~/HEXAeBPF/src/operators/HEXAeBPF_Operator/HEXAeBPF-open5gs-eupf-operator/hexa-open5gs-eupf-cp-operator && make undeploy
""",
    "Open5GS-OAI-UPF-eBPF": """
kubectl delete -f ~/HEXAeBPF/src/operators/HEXAeBPF_Operator/HEXAeBPF-open5gs-eupf-operator/hexa-open5gs-eupf-up-operator/config/samples/eupf_v1_hexaup.yaml -n hexa
cd ~/HEXAeBPF/src/operators/HEXAeBPF_Operator/HEXAeBPF-open5gs-eupf-operator/hexa-open5gs-eupf-up-operator && make undeploy
""",
    "Free5GC-edgecomllc/eUPF": """
kubectl delete -f ~/HEXAeBPF/src/operators/HEXAeBPF_Operator/HEXAeBPF-free5gc-eupf-operator/hexa-free5gc-eupf-cp-operator/config/samples/free5gc_v1_hexacp.yaml -n hexa
cd ~/HEXAeBPF/src/operators/HEXAeBPF_Operator/HEXAeBPF-free5gc-eupf-operator/hexa-free5gc-eupf-cp-operator && make undeploy
""",
    "Free5GC-OAI-UPF-eBPF": """
kubectl delete -f ~/HEXAeBPF/src/operators/HEXAeBPF_Operator/HEXAeBPF-free5gc-eupf-operator/hexa-free5gc-eupf-up-operator/config/samples/eupf_v1_hexaup.yaml -n hexa
cd ~/HEXAeBPF/src/operators/HEXAeBPF_Operator/HEXAeBPF-free5gc-eupf-operator/hexa-free5gc-eupf-up-operator && make undeploy
""",
}


# def undeploy_menu():
#     console.print("\n[bold cyan]Undeploy HEXAeBPF Operators[/bold cyan]\n")

#     undeploy_options = list(undeploy_commands.keys()) + ["All Operators", "Go Back"]
#     console.print("[bold yellow]Available Components for Undeployment:[/bold yellow]")
#     for idx, option in enumerate(undeploy_options, start=1):
#         console.print(f"  {idx}. {option}")

#     choice = IntPrompt.ask("Select Component to Undeploy (enter number)")
    
#     if choice == len(undeploy_options):  # Go Back
#         return main_menu()

#     elif choice == len(undeploy_options) - 1:  # All Operators
#         log_file = "logs/undeployment_logs.txt"
#         os.makedirs("logs", exist_ok=True)
#         console.print("\n[bold yellow]Undeploying All Operators...[/bold yellow]")
#         for operator, command in undeploy_commands.items():
#             console.print(f"[bold cyan]Undeploying {operator}...[/bold cyan]")
#             execute_command(command, log_file)
#         console.print("[bold green]All operators undeployed successfully![/bold green]")
#     elif 1 <= choice < len(undeploy_options) - 1:
#         selected_operator = undeploy_options[choice - 1]
#         log_file = "logs/undeployment_logs.txt"
#         os.makedirs("logs", exist_ok=True)
#         console.print(f"[bold yellow]Undeploying {selected_operator}...[/bold yellow]")
#         execute_command(undeploy_commands[selected_operator], log_file)
#         console.print(f"[bold green]{selected_operator} undeployed successfully![/bold green]")
#     else:
#         # console.print("[bold red]Invalid choice. Returning to main menu.[/bold red]")
#         show_error("Invalid choice. Please select a valid option.")


#     main_menu()

def undeploy_menu():
    console.print("\n[bold cyan]Undeploy HEXAeBPF Operators[/bold cyan]\n")

    # Add styled header
    panel_title = "Available Components for Undeployment"
    undeploy_options = list(undeploy_commands.keys()) + ["All Operators", "Go Back"]

    # Format options into a numbered list with proper alignment
    formatted_options = "\n".join(
        [f"[bold yellow]{idx}.[/bold yellow] {option}" for idx, option in enumerate(undeploy_options, start=1)]
    )

    # Display in a styled panel
    console.print(
        Panel(
            Align.left(formatted_options),
            title=panel_title,
            title_align="left",
            border_style="green",
            padding=(1, 2),
        )
    )

    # Ask for user input
    choice = IntPrompt.ask("Select Component to Undeploy (enter number)")

    if choice == len(undeploy_options):  # Go Back
        return main_menu()

    elif choice == len(undeploy_options) - 1:  # All Operators
        log_file = "logs/undeployment_logs.txt"
        os.makedirs("logs", exist_ok=True)
        console.print("\n[bold yellow]Undeploying All Operators...[/bold yellow]")
        for operator, command in undeploy_commands.items():
            console.print(f"[bold cyan]Undeploying {operator}...[/bold cyan]")
            execute_command(command, log_file)
        console.print("[bold green]All operators undeployed successfully![/bold green]")
    elif 1 <= choice < len(undeploy_options) - 1:
        selected_operator = undeploy_options[choice - 1]
        log_file = "logs/undeployment_logs.txt"
        os.makedirs("logs", exist_ok=True)
        console.print(f"[bold yellow]Undeploying {selected_operator}...[/bold yellow]")
        execute_command(undeploy_commands[selected_operator], log_file)
        console.print(f"[bold green]{selected_operator} undeployed successfully![/bold green]")
    else:
        show_error("Invalid choice. Please select a valid option.")

    main_menu()



# Operator commands for deployment
deployment_commands = {
    "Control Plane": {
        "SD Core": lambda amf_ip: f"""
cd ~/HEXAeBPF/src/operators/HEXAeBPF_Operator/HEXAeBPF-sdcore-eupf-operator/hexa-sdcore-eupf-cp-operator
make install
make deploy IMG=evershalik/hexa-sdcore-eupf-cp-operator:v2.0
sleep 30
echo "AMF_IP to be used in configuration: {amf_ip}"
sed -i 's/externalIp: .*/externalIp: {amf_ip}/' config/samples/sdcore_v1_hexacp.yaml
cat config/samples/sdcore_v1_hexacp.yaml | grep externalIp
kubectl apply -f config/samples/sdcore_v1_hexacp.yaml -n hexa
""",
        "Free5GC": """
cd ~/HEXAeBPF/src/operators/HEXAeBPF_Operator/HEXAeBPF-free5gc-eupf-operator/hexa-free5gc-eupf-cp-operator
make install
make deploy IMG=evershalik/hexa-free5gc-eupf-cp-operator:v2.0
sleep 30
kubectl apply -f config/samples/free5gc_v1_hexacp.yaml -n hexa
""",
        "Open5GS": """
cd ~/HEXAeBPF/src/operators/HEXAeBPF_Operator/HEXAeBPF-open5gs-eupf-operator/hexa-open5gs-eupf-cp-operator
make install
make deploy IMG=evershalik/hexa-open5gs-eupf-cp-operator:v2.0
sleep 30
kubectl apply -f config/samples/open5gs_v1_hexacp.yaml -n hexa
""",
        "OAI": """
cd ~/HEXAeBPF/src/operators/HEXAeBPF_Operator/HEXAeBPF-oai-ebpf-operator/hexa-oai-ebpf-operator
make install
make deploy IMG=evershalik/hexa-oai-ebpf-operator:v2.0
sleep 30
kubectl apply -f config/samples/oai.ebpf_v1_hexaoai.yaml -n hexa
""",
    },
    "User Plane": {
        "edgecomllc/eUPF": {
            "SD Core": """
cd ~/HEXAeBPF/src/operators/HEXAeBPF_Operator/HEXAeBPF-sdcore-eupf-operator/hexa-sdcore-eupf-up-operator
make install
make deploy IMG=evershalik/hexa-sdcore-eupf-up-operator:v2.0
sleep 30
kubectl apply -f config/samples/eupf_v1_hexaup.yaml -n hexa
""",
            "Free5GC": """
cd ~/HEXAeBPF/src/operators/HEXAeBPF_Operator/HEXAeBPF-free5gc-eupf-operator/hexa-free5gc-eupf-up-operator
make install
make deploy IMG=evershalik/hexa-free5gc-eupf-up-operator:v2.0
sleep 30
kubectl apply -f config/samples/eupf_v1_hexaup.yaml -n hexa
sleep 30
cd /home/ubuntu/HEXAeBPF/src/operators/HEXAeBPF_Operator/HEXAeBPF-free5gc-eupf-operator/hexa-free5gc-eupf-cp-operator/webui_automation
bash add_subscriber.sh
""",
            "Open5GS": """
cd ~/HEXAeBPF/src/operators/HEXAeBPF_Operator/HEXAeBPF-open5gs-eupf-operator/hexa-open5gs-eupf-up-operator
make install
make deploy IMG=evershalik/hexa-open5gs-eupf-up-operator:v2.0
sleep 30
kubectl apply -f config/samples/eupf_v1_hexaup.yaml -n hexa
sleep 90
""",
        },
        "OAI-UPF-eBPF": """
cd ~/HEXAeBPF/src/operators/HEXAeBPF_Operator/HEXAeBPF-oai-ebpf-operator/hexa-oai-ebpf-operator
make install
make deploy IMG=evershalik/hexa-oai-ebpf-operator:v2.0
sleep 30
kubectl apply -f config/samples/oai.ebpf_v1_hexaoai.yaml -n hexa
""",
    },
    "RAN Simulator": {
        "UERANSIM": lambda control_plane: f"""
cd ~/HEXAeBPF/src/operators/HEXAeBPF_Operator/HEXAeBPF-ueransim-operator/hexa-ueransim-operator
make install
make deploy IMG=evershalik/hexa-ueransim-operator:v2.0
sleep 30
echo "AMF_IP to be used in configuration: {AMF_IP}"
sed -i '/amf:/{{n;s/^[ \t]*ip:.*/    ip: {AMF_IP}/;}}' config/samples/{'sdcore' if control_plane == 'SD Core' else ''}_v1_hexaueransim.yaml
echo "Updated Configuration:"
cat config/samples/{'sdcore' if control_plane == 'SD Core' else control_plane.lower().replace(' ', '_')}_v1_hexaueransim.yaml | grep ip
kubectl apply -f config/samples/{'sdcore' if control_plane == 'SD Core' else control_plane.lower().replace(' ', '_')}_v1_hexaueransim.yaml -n hexa
""",
        "OAI-RFSimulator": """
cd ~/HEXAeBPF/src/operators/HEXAeBPF_Operator/HEXAeBPF-oai-rfsimulator-operator/hexa-oai-gnb-operator
make install
make deploy IMG=evershalik/hexa-oai-gnb-operator:v2.0
sleep 30
kubectl apply -f config/samples/oai.gnb_v1_hexaoaignb.yaml -n hexa
cd ~/HEXAeBPF/src/operators/HEXAeBPF_Operator/HEXAeBPF-oai-rfsimulator-operator/hexa-oai-nr-ue-operator
make install
make deploy IMG=evershalik/hexa-oai-nr-ue-operator:v2.0
sleep 30
kubectl apply -f config/samples/oai.nr.ue_v1_hexaoainrue.yaml -n hexa
""",
    },
}


# Completers for autocompletion
control_plane_completer = WordCompleter(control_planes)
user_plane_completer = WordCompleter(user_planes)

def execute_command(command, log_file):
    """
    Executes a shell command and logs both the command and its output to a file.
    """
    with open(log_file, "a") as log:
        log.write(f"\nExecuting: {command}\n{'='*40}\n")
        process = subprocess.Popen(
            command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
        )
        stdout, stderr = process.communicate()
        
        # Log the outputs
        if stdout:
            log.write(f"STDOUT:\n{stdout}\n{'='*40}\n")
        if stderr:
            log.write(f"STDERR:\n{stderr}\n{'='*40}\n")
        
        return process.returncode



def main_menu():

    console.print("\n")
    # Welcome panel
    welcome_message = (
        "[bold yellow]╔══════════════════════════════════════════════════════════════╗\n"
        "║                     [bold cyan]Welcome to HEXAeBPF[/bold cyan]                      ║\n"
        "╚══════════════════════════════════════════════════════════════╝[/bold yellow]"
    )
    console.print(
        Panel(
            Align.center(welcome_message),
            title="HEXAeBPF CLI",
            subtitle="Effortless Deployments",
            border_style="bright_blue",
            padding=(1, 2),
            expand=True,  # Ensures full-width alignment
        )
    )
    console.print("\n")

    # Main Menu
    console.print(Panel(
        Align.left("""
[bold yellow]1.[/bold yellow] [bright_white]Deploy HEXAeBPF Operators[/bright_white]
[bold yellow]2.[/bold yellow] [bright_white]Undeploy HEXAeBPF Operators[/bright_white]
[bold yellow]3.[/bold yellow] [bright_white]Clear Logs[/bright_white]
[bold yellow]4.[/bold yellow] [bright_white]View Logs[/bright_white]
[bold yellow]5.[/bold yellow] [bright_white]Manage Operators[/bright_white]
[bold yellow]6.[/bold yellow] [bright_white]Help[/bright_white]
[bold yellow]0.[/bold yellow] [bright_white]Exit[/bright_white]
        """),
        title="[green]Main Menu[/green]",
        border_style="green",
        padding=(1, 4),
    ))

    # Prompt for selection
    choice = IntPrompt.ask(
    "[bold cyan]Choose an option[/bold cyan]")
    if choice == 1:
        console.print()
        deploy_menu()
    elif choice == 2:
        undeploy_menu()
    elif choice == 3:
        clean_up_logs()
    elif choice == 4:
        view_logs()
    elif choice == 5:
        manage_operators()
    elif choice == 6:
        show_help()
    elif choice == 0:
        console.print()
        console.print(
            Panel.fit(
                "\n[bold green]Exiting [bright_blue]HEXAeBPF CLI[/bright_blue]. [bold cyan]Goodbye![/bold cyan] :smiley:",
                title="[bright_green]Exit[/bright_green]",
                border_style="bright_green",
            )
        )
        console.print()
        # Detach from the tmux session if running inside one
        time.sleep(0.5)
        os.system("tmux detach")
        sys.exit(0)
    else:
        # console.print("[bold red]Invalid choice. Try again.[/bold red]")
        show_error("Invalid choice. Please select a valid option.")
        main_menu()

def simulate_progress(task_name, duration=5):
    with Progress() as progress:
        task = progress.add_task(f"[green]{task_name}...", total=100)
        for _ in range(100):
            time.sleep(duration / 100)
            progress.advance(task)

def deploy_menu():
    global AMF_IP
    # console.print("\n[bold cyan]Deploy HEXAeBPF Operators[/bold cyan]\n")
    
    # Display the section header
    console.print(Panel.fit(
        "\n[bold cyan]Deploy HEXAeBPF Operators[/bold cyan]",
        border_style="bright_cyan",
        title="\n[bold blue]Deployment Section[/bold blue]"
    ))

    #storing logs
    log_file = "logs/deployment_logs.txt"
    os.makedirs("logs", exist_ok=True)

    # Select Control Plane
    # console.print("[bold yellow]Available Control Planes:[/bold yellow]")
    # for idx, cp in enumerate(control_planes, start=1):
    #     console.print(f"  {idx}. {cp}")

    # Available Control Planes
    console.print(Panel(
    "\n".join([f"[bold yellow]{idx}. [bold white]{cp}" for idx, cp in enumerate(control_planes, start=1)]),
    title="[bold yellow]Available Control Planes[/bold yellow]",
    border_style="green",
    padding=(1, 2),
    expand=True
    ))
    control_plane = get_valid_choice(
    "[bold cyan]Select Control Plane (enter number)[/bold cyan]",
    control_planes
    )
    console.print("\n")

    if control_plane == "SD Core":
        while True:
            console.print(
                Panel.fit(
                    "\nEnter the [bold cyan]AMF External IP[/bold cyan] in the format [bold green]192.168.x.x[/bold green]\n",
                    title="[bold yellow]AMF External IP Required[/bold yellow]",
                    border_style="cyan",
                )
            )
            console.print()
            AMF_IP = Prompt.ask("[bold cyan]Enter the AMF External IP[/bold cyan] (e.g., [green]192.168.6.16[/green])").strip()
            console.print()
            # Validate the IP format
            import re
            if re.match(r"^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$", AMF_IP):
                console.print(
                    Panel.fit(
                        f"\n[bold green]:white_check_mark: AMF IP Address set to: {AMF_IP}[/bold green]\n",
                        title="[bold green]Success[/bold green]",
                        border_style="green",
                    )
                )
                break
            else:
                console.print(
                    Panel.fit(
                        "\n[bold red]:x: Invalid IP format. Please re-enter a valid IP address![/bold red]\n",
                        title="[bold red]Error[/bold red]",
                        border_style="red",
                    )
                )
                continue  # Re-prompt the user
            
        control_plane_command = deployment_commands["Control Plane"]["SD Core"](AMF_IP)
    else:
        control_plane_command = deployment_commands["Control Plane"][control_plane]

    console.print(Panel(
    "\n".join([f"[bold yellow]{idx}. [bold white]{up}" for idx, up in enumerate(user_planes, start=1)]),
    title="[bold yellow]Available User Planes[/bold yellow]",
    border_style="green",
    padding=(1, 2),
    expand=True
    ))
    user_plane = get_valid_choice(
    "[bold cyan]Select User Plane (enter number)[/bold cyan]",
    user_planes
    )
    console.print("\n")

    # Validate User Plane compatibility
    if isinstance(deployment_commands["User Plane"][user_plane], dict):
        if control_plane not in deployment_commands["User Plane"][user_plane]:
            console.print(
                f"[bold red]The selected User Plane '{user_plane}' is not compatible with the Control Plane '{control_plane}'. Aborting deployment![/bold red]"
            )
            main_menu()
            return
        user_plane_command = deployment_commands["User Plane"][user_plane][control_plane]
    else:
        if user_plane == "OAI-UPF-eBPF" and control_plane != "OAI":
            console.print(
                f"[bold red]The selected User Plane '{user_plane}' is only compatible with the 'OAI' Control Plane. Aborting deployment![/bold red]"
            )
            main_menu()
            return
        elif control_plane == "OAI":
            console.print(
                f"[bold yellow]Skipping User Plane deployment as '{control_plane}' already includes User Plane components.[/bold yellow]"
            )
            user_plane_command = None
        else:
            user_plane_command = deployment_commands["User Plane"][user_plane]

    # Available RAN Simulators
    ran_simulators = ran_simulators_oai if control_plane == "OAI" else ran_simulators_common
    
    # Create a list of available RAN simulators with a numbered list
    ran_simulator_list = "\n".join(
        f"[bold yellow]{idx}. [bold white]{rs}" for idx, rs in enumerate(ran_simulators, start=1)
    )
    
    # Display the options in a styled panel
    console.print(
        Panel.fit(
            Align.left(ran_simulator_list),
            title="[bold yellow]Available RAN Simulators[/bold yellow]",
            border_style="green",
            padding=(1, 2),
        )
    )
    
    # Prompt for user selection
    ran_simulator = get_valid_choice(
        "[bold cyan]Select RAN Simulator (enter number):[/bold cyan]", ran_simulators
    )
    
    # Set the command based on the selection
    if ran_simulator == "UERANSIM":
        ran_simulator_command = deployment_commands["RAN Simulator"]["UERANSIM"](control_plane)
    else:
        ran_simulator_command = deployment_commands["RAN Simulator"][ran_simulator]

    # Deployment Details Table
    details_table = Table(title="[bold cyan]Deployment Details[/bold cyan]", box=HEAVY, highlight=True)
    details_table.add_column("[bold magenta]Component[/bold magenta]", justify="center")
    details_table.add_column("[bold green]Selection[/bold green]", justify="center")

    details_table.add_row("[bold magenta]Control Plane[/bold magenta]", f"[bold green]{control_plane}[/bold green]")
    details_table.add_row("[bold magenta]User Plane[/bold magenta]", f"[bold green]{user_plane}[/bold green]")
    details_table.add_row("[bold magenta]RAN Simulator[/bold magenta]", f"[bold green]{ran_simulator}[/bold green]")

    # Use Panel to wrap the table
    console.print(Panel.fit(details_table, border_style="bright_cyan", padding=(1, 2)))

    # Confirm Deployment
    confirm_panel = Panel(
        Align.center(
            "Do you wish to proceed with the deployment?",
            vertical="middle"
        ),
        title="[bold cyan]Deployment Confirmation[/bold cyan]",
        subtitle="Make your choice wisely!",
        border_style="cyan",
        padding=(1, 2),
    )
    console.print()
    console.print(confirm_panel)
    confirm = Prompt.ask("\nYour choice", choices=["y", "n"])

    if confirm == "y":
        with Progress() as progress:
            task = progress.add_task("[green]Deploying HEXAeBPF Operators...", total=100)

            # Deploy Control Plane
            progress.update(task, description="[green]Deploying Control Plane...")
            execute_command(control_plane_command, log_file)
            console.print("\n[bold yellow]Waiting for 3 minutes to ensure Control Plane is ready...[/bold yellow]")
            time.sleep(180)
            progress.advance(task, 33)

            # Deploy User Plane
            if user_plane_command:
                progress.update(task, description="[green]Deploying User Plane...")
                execute_command(user_plane_command, log_file)
                console.print("\n[bold yellow]Waiting for 2 minutes to ensure User Plane is ready...[/bold yellow]")
                time.sleep(120)
                progress.advance(task, 33)

            # Deploy RAN Simulator
            progress.update(task, description="[green]Deploying RAN Simulator...")
            execute_command(ran_simulator_command, log_file)
            console.print("\n[bold yellow]Waiting for 3 minutes to ensure RAN Simulator is ready...[/bold yellow]")
            time.sleep(180)
            progress.advance(task, 34)
        


    
        # Deployment Completion Message
        console.print(
            Panel(
                "[bold green]🎉 Deployment Complete![/bold green]\n\n[bold white]Everything is ready for use![/bold white]",
                border_style="green",
                padding=(1, 2),
            )
        )   
    else:
        console.print(
            Panel(
                "[bold red]❌ Deployment Cancelled.[/bold red]\n\n[bold white]You can return to the main menu.[/bold white]",
                border_style="red",
                padding=(1, 2),
            )
        )

    main_menu()
    


def manage_operators():
    console.print("\n[bold cyan]Manage HEXAeBPF Operators[/bold cyan]\n")
    console.print("Feature under development. Returning to main menu.")
    main_menu()

def view_logs():
    console.print("\n[bold cyan]View Deployment Logs[/bold cyan]\n")
    log_file = "logs/deployment_logs.txt"
    if os.path.exists(log_file):
        with open(log_file, "r") as log:
            log_content = log.read()
        console.print(Panel(f"[white on black]{log_content}[/white on black]", title="Deployment Logs"))
    else:
        show_error("No logs found. Please deploy components first.")
    main_menu()



def clean_up_logs():
    console.print("\n[bold cyan]Clear Logs[/bold cyan]\n")
    log_file = "logs/deployment_logs.txt"
    if os.path.exists(log_file):
        os.remove(log_file)
        console.print("[bold green]Deployment logs cleared.[/bold green]")
    else:
        console.print("[bold yellow]No logs to clear.[/bold yellow]")
    # # Add cleanup commands for resources here if needed
    # console.print("[bold green]Resources cleaned up successfully.[/bold green]")
    main_menu()

def show_error(error_message):
    console.print(Panel(f"[bold red]{error_message}[/bold red]", title="Error", border_style="red"))


def get_valid_choice(prompt_message, options):
    """
    Prompts the user to select an option and ensures the choice is valid.
    """
    while True:
        try:
            choice = IntPrompt.ask(prompt_message)
            if 1 <= choice <= len(options):  # Ensure choice is within valid range
                return options[choice - 1]  # Return the selected option
            else:
                # console.print("[bold red]Invalid choice. Please select a valid option.[/bold red]")
                show_error("Invalid choice. Please select a valid option.")
        except ValueError:
            console.print("[bold red]Please enter a number corresponding to your choice.[/bold red]")


def show_help():
    console.print("\n[bold cyan]HEXAeBPF CLI Help[/bold cyan]\n")
    console.print("""
[1] Deploy HEXAeBPF Operators:
    - Deploy Control Plane, User Plane, and RAN Simulator components.
    - You can mix and match Control and User Planes as per compatibility.
    - Logs of the deployment are stored in 'logs/deployment_logs.txt'.

[2] Undeploy HEXAeBPF Operators:
    - Undeploy specific operators or components.

[3] Clear Logs:
    - Clears availabs history and logs.
    
[4] View Logs:
    - Displays the logs of the most recent deployment.
    - Logs are cleared upon performing Clear Logs.

[5] Manage Operators:
    - Scale deployments, restart pods, or check status (Feature in development).

[6] Help:
    - Displays this help message.

[0] Exit:
    - Exits the CLI.

For more information, refer to the HEXAeBPF documentation.
    """)
    main_menu()


if __name__ == "__main__":
    main_menu()
