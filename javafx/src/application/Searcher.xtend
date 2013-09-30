package application

import com.google.common.io.Files
import java.io.File
import java.util.concurrent.ForkJoinPool
import javafx.concurrent.Task
import rx.Observable

class Searcher {
	static val EXECUTOR = new ForkJoinPool

	def static Observable<String> search(String searchExpression) {
		if (searchExpression.length < 2) {
			return Observable.never
		}

		val traverser = Files.fileTreeTraverser

		Observable.<String> create[
			
			val Task<Void> task = [|
				for (file : traverser.breadthFirstTraversal(new File("D:/Soft"))) {
					if (self.isCancelled) {
						return null
					}

					if (file.name.contains(searchExpression)) {
						onNext(file.absolutePath)
					}
				}
				
				null
			]
			
			EXECUTOR.submit(task)
			
			return [|
				task.cancel
			]
		]
	}
}
