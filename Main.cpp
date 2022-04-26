#include<iostream>
#include<glad/glad.h>
#include<GLFW/glfw3.h>

const char* vertexShaderSource =
"#version 337 core\n"
"layout (location = 0) in vec3 aPos;"
"void main() {\n"
"gl_Position = Vec4(aPos.x, aPos.y, aPos.z, 1.0);"
"}\0";

const char* fragmentShaderSource =
"#version 337 core\n"
"out vec4 FragColor"
"void main() {\n"
"FragColor = Vec4(1.0f, 0.0f, 0.0f, 1.0f);\n"
"}\0";

int main() {
	glfwInit();
	glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
	glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
	glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

	GLFWwindow* window = glfwCreateWindow(512, 512, "Test", NULL, NULL);
	if (window == NULL) {
		std::cout << "Failed to create GLFW Window" << std::endl;
		glfwTerminate();
		return -1;
	}
	glfwMakeContextCurrent(window);

	gladLoadGL();
	glViewport(0, 0, 512, 512);

	GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);
	glShaderSource(vertexShader, 1, &vertexShaderSource, NULL);
	glCompileShader(vertexShader);

	GLuint fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
	glShaderSource(fragmentShader, 1, &fragmentShaderSource, NULL);
	glCompileShader(fragmentShader);

	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
	glClear(GL_COLOR_BUFFER_BIT);
	glfwSwapBuffers(window);

	while (!glfwWindowShouldClose(window)) {
		glfwPollEvents();
	}

	glfwDestroyWindow(window);
	glfwTerminate();
	return 0;
}