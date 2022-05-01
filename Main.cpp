#include<iostream>
#include<glad/glad.h>
#include<GLFW/glfw3.h>
#include<string>
#include<fstream>
#include<imgui.h>
#include<imgui_impl_glfw.h>
#include<imgui_impl_opengl3.h>
using namespace std;
using namespace std;

string title = "Shadertoy GLSL - 0.0.1 - ";
const int height = 768;
const int width = height * 2;

const char* vertexShaderSource =
"#version 330 core\n"
"layout (location = 0) in vec3 aPos;\n"
"void main() {\n"
"gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);\n"
"}\0";
const char* fragmentShaderSource =
"#version 330 core\n"
"out vec4 FragColor;\n"
"void main() {\n"
"FragColor = vec4(gl_FragCoord.x/(2.0f*768.0f), gl_FragCoord.y/768.0f, 0.0f, 1.0f);\n"
"}\0";

const ImGuiWindowFlags noResizeFlags = ImGuiWindowFlags_NoCollapse | ImGuiWindowFlags_NoResize;

GLuint loadShaderFromFile(string path, GLenum shaderType)
{
	GLuint shaderID = 0;
	string shaderString;
	ifstream sourceFile(path.c_str());
	if (sourceFile)
	{
		shaderString.assign((istreambuf_iterator< char >(sourceFile)), istreambuf_iterator< char >());
		shaderID = glCreateShader(shaderType);
		const GLchar* shaderSource = shaderString.c_str();
		glShaderSource(shaderID, 1, (const GLchar**)&shaderSource, NULL);
		glCompileShader(shaderID);
		GLint shaderCompiled = GL_FALSE;
		glGetShaderiv(shaderID, GL_COMPILE_STATUS, &shaderCompiled);
		if (shaderCompiled != GL_TRUE)
		{
			printf("Unable to compile shader %d!\n\nSource:\n%s\n", shaderID, shaderSource);
			glDeleteShader(shaderID);
			shaderID = 0;
		}
	}
	else
	{
		printf("Unable to open file %s\n", path.c_str());
	}
	return shaderID;
}

int main() {
	glfwInit();
	glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
	glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
	glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

	GLfloat vertices[] = {
		-1.0f, -4.0f, 0.0f,
		-1.0f, 1.0f, 0.0f,
		4.0f, 1.0f, 0.0f
	};

	GLFWwindow* window = glfwCreateWindow(width, height, "Loading OpenGL", NULL, NULL);
	if (window == NULL) {
		cout << "Failed to create GLFW Window" << endl;
		glfwTerminate();
		return -1;
	}

	glfwMakeContextCurrent(window);
	gladLoadGL();
	glViewport(0, 0, width, height);

	GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);
	glShaderSource(vertexShader, 1, &vertexShaderSource, NULL);
	glCompileShader(vertexShader);

	GLuint fragmentShader = loadShaderFromFile("assets\\round.glsl", GL_FRAGMENT_SHADER);

	GLuint shaderProgram = glCreateProgram();
	glAttachShader(shaderProgram, vertexShader);
	glAttachShader(shaderProgram, fragmentShader);
	glLinkProgram(shaderProgram);
	glDetachShader(shaderProgram, fragmentShader);
	glDeleteShader(vertexShader);
	glDeleteShader(fragmentShader);

	GLuint VAO, VBO;
	glGenVertexArrays(1, &VAO);
	glGenBuffers(1, &VBO);
	glBindVertexArray(VAO);
	glBindBuffer(GL_ARRAY_BUFFER, VBO);
	glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
	glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), (void*)0);
	glEnableVertexAttribArray(0);
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindVertexArray(0);

	IMGUI_CHECKVERSION();
	ImGui::CreateContext();
	ImGuiIO& io = ImGui::GetIO(); (void)io;
	ImGui::StyleColorsDark();
	ImGui_ImplGlfw_InitForOpenGL(window, true);
	ImGui_ImplOpenGL3_Init("#version 330");
	ImFont* firacode = io.Fonts->AddFontFromFileTTF("assets\\FiraCode-Regular.ttf", 16);

	double previousTime = glfwGetTime();
	int frameCount = 0;

	while (!glfwWindowShouldClose(window)) {
		double currentTime = glfwGetTime();
		frameCount++;
		if (currentTime - previousTime >= 1.0)
		{
			string titleTemp = title + to_string(frameCount) + " fps";
			char* ctitle = &titleTemp[0];
			glfwSetWindowTitle(window, ctitle);
			frameCount = 0;
			previousTime = currentTime;
		}

		glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
		glClear(GL_COLOR_BUFFER_BIT);

		ImGui_ImplOpenGL3_NewFrame();
		ImGui_ImplGlfw_NewFrame();
		ImGui::NewFrame();

		glUseProgram(shaderProgram);
		GLint resUniform = glGetUniformLocation(shaderProgram, "iResolution");
		glUniform3f(resUniform, width, height, width / height);
		double mxpos, mypos;
		glfwGetCursorPos(window, &mxpos, &mypos);
		GLint mouseUniform = glGetUniformLocation(shaderProgram, "iMouse");
		glUniform4f(mouseUniform, mxpos, mypos, mxpos, mypos);
		GLint timeUniform = glGetUniformLocation(shaderProgram, "iTime");
		glUniform1f(timeUniform, currentTime);
		glBindVertexArray(VAO);
		glDrawArrays(GL_TRIANGLES, 0, 3);

		ImGui::PushFont(firacode);
		ImGui::PushStyleVar(ImGuiStyleVar_WindowMinSize, { 120.f, 100.f });
		ImGui::Begin("Shader Options", (bool*)nullptr, noResizeFlags);
		string shader;
		//if (ImGui::InputText("Asset Name: ", &shader)) {

		//}
		if (ImGui::Button("Reload Shader", ImVec2(0, 0))) {
			glDetachShader(shaderProgram, fragmentShader);
			fragmentShader = loadShaderFromFile("assets\\round.glsl", GL_FRAGMENT_SHADER);
			glAttachShader(shaderProgram, fragmentShader);
			glLinkProgram(shaderProgram);
			glDetachShader(shaderProgram, fragmentShader);
			glDeleteShader(fragmentShader);
		}
		ImGui::PopFont();
		ImGui::End();

		ImGui::Render();
		ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());

		glfwSwapBuffers(window);
		glfwPollEvents();
	}

	ImGui_ImplOpenGL3_Shutdown();
	ImGui_ImplGlfw_Shutdown();
	ImGui::DestroyContext();

	glDeleteVertexArrays(1, &VAO);
	glDeleteBuffers(1, &VBO);
	glDeleteProgram(shaderProgram);

	glfwDestroyWindow(window);
	glfwTerminate();
	return 0;
}